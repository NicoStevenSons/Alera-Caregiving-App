import 'dart:async';

import 'package:alera/features/reminders/data/home_reminder_controller.dart';
import 'package:alera/features/reminders/data/reminder_api_data_source.dart';
import 'package:alera/features/reminders/domain/reminder_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Manila day changes at 16:00 UTC', () {
    expect(
      manilaDayStartUtc(DateTime.utc(2026, 10, 4, 15, 59, 59)),
      DateTime.utc(2026, 10, 3, 16),
    );
    expect(
      manilaDayStartUtc(DateTime.utc(2026, 10, 4, 16)),
      DateTime.utc(2026, 10, 4, 16),
    );
  });

  test('fetches all pages with the same patient and Manila bounds', () async {
    final source = _Source((patient, offset) async {
      final count = offset == 0 ? 100 : 1;
      return _page(
        List.generate(count, (i) => _item('${offset + i}', patient)),
        total: 101,
        offset: offset,
      );
    });
    final controller = _controller(source);
    addTearDown(controller.dispose);

    await controller.loadForPatient('a');

    expect(controller.occurrences, hasLength(101));
    expect(source.calls.map((call) => call.$4), [0, 100]);
    for (final call in source.calls) {
      expect(call.$1, 'a');
      expect(call.$2, DateTime.utc(2026, 10, 3, 16));
      expect(call.$3, DateTime.utc(2026, 10, 4, 16));
    }
    expect(controller.errorMessage, isNull);
  });

  test('patient switch rejects a delayed previous response', () async {
    final pending = Completer<ReminderPage<ReminderOccurrence>>();
    final source = _Source((patient, offset) {
      if (patient == 'a') return pending.future;
      return Future.value(_page([_item('b-reminder', 'b')]));
    });
    final controller = _controller(source);
    addTearDown(controller.dispose);

    final oldLoad = controller.loadForPatient('a');
    await controller.loadForPatient('b');
    pending.complete(_page([_item('a-reminder', 'a')]));
    await oldLoad;

    expect(controller.patientId, 'b');
    expect(controller.occurrences.single.id, 'b-reminder');
    expect(controller.loading, isFalse);
  });

  test('failed later page does not publish a partial list', () async {
    final source = _Source((patient, offset) async {
      if (offset > 0) throw const ReminderApiFailure('Offline');
      return _page([_item('first', patient)], total: 2);
    });
    final controller = _controller(source);
    addTearDown(controller.dispose);

    await controller.loadForPatient('a');

    expect(controller.occurrences, isEmpty);
    expect(controller.errorMessage, 'Offline');
    expect(controller.loading, isFalse);
  });

  test('ensureLoaded fetches again after Manila midnight', () async {
    var now = DateTime.utc(2026, 10, 4, 15, 59);
    final source = _Source((patient, offset) async => _page([]));
    final controller = HomeReminderController(
      dataSource: source,
      now: () => now,
    );
    addTearDown(controller.dispose);

    await controller.ensureLoaded('a');
    await controller.ensureLoaded('a');
    expect(source.calls, hasLength(1));

    now = DateTime.utc(2026, 10, 4, 16);
    await controller.ensureLoaded('a');
    expect(source.calls, hasLength(2));
    expect(source.calls.last.$2, DateTime.utc(2026, 10, 4, 16));
  });

  test('rejects reminders belonging to another patient', () async {
    final source = _Source(
      (patient, offset) async => _page([_item('wrong-patient', 'other')]),
    );
    final controller = _controller(source);
    addTearDown(controller.dispose);

    await controller.loadForPatient('a');

    expect(controller.occurrences, isEmpty);
    expect(controller.errorMessage, isNotNull);
  });

  test('clear invalidates a pending request', () async {
    final pending = Completer<ReminderPage<ReminderOccurrence>>();
    final source = _Source((patient, offset) => pending.future);
    final controller = _controller(source);
    addTearDown(controller.dispose);

    final loading = controller.loadForPatient('a');
    controller.clear();
    pending.complete(_page([_item('late', 'a')]));
    await loading;

    expect(controller.patientId, isNull);
    expect(controller.occurrences, isEmpty);
    expect(controller.loading, isFalse);
  });
}

HomeReminderController _controller(_Source source) => HomeReminderController(
  dataSource: source,
  now: () => DateTime.utc(2026, 10, 4, 9),
);

ReminderPage<ReminderOccurrence> _page(
  List<ReminderOccurrence> items, {
  int? total,
  int offset = 0,
}) => ReminderPage(
  items: items,
  total: total ?? items.length,
  limit: 100,
  offset: offset,
);

ReminderOccurrence _item(String id, String patientId) => ReminderOccurrence(
  id: id,
  templateId: 'template',
  patientId: patientId,
  title: 'Medication',
  category: ReminderCategory.medication,
  priority: ReminderPriority.normal,
  scheduledAt: DateTime.utc(2026, 10, 4, 8),
  dueAt: DateTime.utc(2026, 10, 4, 8, 15),
  status: ReminderOccurrenceStatus.due,
  snoozeAllowed: true,
  defaultSnoozeMinutes: 10,
  missedAfterMinutes: 30,
);

class _Source implements ReminderDateRangeDataSource {
  _Source(this.respond);
  final Future<ReminderPage<ReminderOccurrence>> Function(String, int) respond;
  final calls = <(String, DateTime, DateTime, int)>[];

  @override
  Future<ReminderPage<ReminderOccurrence>> fetchOccurrencesInRange({
    required String patientId,
    required DateTime fromAt,
    required DateTime beforeAt,
    int limit = 100,
    int offset = 0,
  }) {
    calls.add((patientId, fromAt, beforeAt, offset));
    return respond(patientId, offset);
  }
}
