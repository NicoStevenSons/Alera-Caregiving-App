import 'dart:async';
import 'package:alera/features/reminders/data/reminder_api_data_source.dart';
import 'package:alera/features/reminders/data/reminder_controller.dart';
import 'package:alera/features/reminders/domain/reminder_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('switch clears old reminders before the new request finishes', () async {
    final source = _DelayedSource();
    final controller = ReminderController(dataSource: source);
    addTearDown(controller.dispose);
    await controller.loadForPatient('patient-a');
    source.pending['patient-b'] = Completer<ReminderPage<ReminderOccurrence>>();

    final loading = controller.loadForPatient('patient-b');
    expect(controller.loading, isTrue);
    expect(controller.occurrences, isEmpty);
    expect(controller.templates, isEmpty);

    source.pending['patient-b']!.completeError(const FormatException());
    await loading;
    expect(controller.loading, isFalse);
    expect(controller.occurrences, isEmpty);
    expect(controller.templates, isEmpty);
    expect(controller.errorMessage, isNotNull);
  });

  test('late reminder load cannot replace the newer patient data', () async {
    final source = _DelayedSource();
    final controller = ReminderController(dataSource: source);
    addTearDown(controller.dispose);
    source.pending['patient-a'] = Completer<ReminderPage<ReminderOccurrence>>();

    final oldLoad = controller.loadForPatient('patient-a');
    await controller.loadForPatient('patient-b');
    source.pending['patient-a']!.complete(
      ReminderPage(items: [_occurrence()], total: 1, limit: 100, offset: 0),
    );
    await oldLoad;

    expect(controller.occurrences, isEmpty);
    expect(controller.templates, isEmpty);
    expect(controller.loading, isFalse);
    expect(controller.errorMessage, isNull);
  });

  test('old action is ignored after switching away and back', () async {
    final source = _DelayedSource();
    final controller = ReminderController(dataSource: source);
    addTearDown(controller.dispose);
    await controller.loadForPatient('patient-a');
    source.action = Completer<ReminderActionResult>();

    final completing = controller.complete('occurrence-id');
    expect(controller.isBusy('occurrence-id'), isTrue);
    await controller.loadForPatient('patient-b');
    await controller.loadForPatient('patient-a');

    source.action!.complete(
      ReminderActionResult(
        reminder: _occurrence(status: ReminderOccurrenceStatus.completed),
        idempotent: false,
      ),
    );
    await completing;

    expect(controller.occurrences.single.status, ReminderOccurrenceStatus.due);
    expect(controller.isBusy('occurrence-id'), isFalse);
  });

  test('loads templates and occurrences for the selected patient', () async {
    final source = _Source();
    final controller = ReminderController(dataSource: source);

    await controller.loadForPatient('patient-a');

    expect(source.patientIds, ['patient-a', 'patient-a']);
    expect(controller.loading, isFalse);
    expect(controller.errorMessage, isNull);
    expect(controller.occurrences.single.id, 'occurrence-id');
    expect(controller.templates.single.id, 'template-id');
  });

  test('action updates only the matching occurrence', () async {
    final source = _Source();
    final controller = ReminderController(dataSource: source);
    await controller.loadForPatient('patient-a');

    await controller.complete('occurrence-id');

    expect(
      controller.occurrences.single.status,
      ReminderOccurrenceStatus.completed,
    );
    expect(controller.isBusy('occurrence-id'), isFalse);
  });

  test('caregiver complete-on-behalf updates the occurrence', () async {
    final source = _Source();
    final controller = ReminderController(dataSource: source);
    await controller.loadForPatient('patient-a');

    await controller.completeOnBehalf('occurrence-id', 'Medication was given.');

    expect(
      controller.occurrences.single.status,
      ReminderOccurrenceStatus.completed,
    );
  });

  test('create refreshes templates and occurrences', () async {
    final source = _Source();
    final controller = ReminderController(dataSource: source);
    await controller.loadForPatient('patient-a');
    final callsBeforeCreate = source.patientIds.length;

    await controller.createTemplate(_draft());

    expect(source.createdDraft?.title, 'Medication');
    expect(source.patientIds.length, callsBeforeCreate + 2);
  });
}

class _Source implements ReminderDataSource {
  final List<String> patientIds = [];
  ReminderTemplateDraft? createdDraft;

  @override
  Future<ReminderPage<ReminderOccurrence>> fetchOccurrences({
    String? patientId,
    List<ReminderOccurrenceStatus> statuses = const [],
    int limit = 100,
    int offset = 0,
  }) async {
    patientIds.add(patientId!);
    return ReminderPage(
      items: [_occurrence()],
      total: 1,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<ReminderPage<ReminderTemplate>> fetchTemplates(
    String patientId, {
    List<ReminderTemplateStatus> statuses = const [],
    int limit = 100,
    int offset = 0,
  }) async {
    patientIds.add(patientId);
    return ReminderPage(
      items: [_template()],
      total: 1,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<ReminderActionResult> complete(
    String occurrenceId, {
    String? note,
  }) async => ReminderActionResult(
    reminder: _occurrence(status: ReminderOccurrenceStatus.completed),
    idempotent: false,
  );

  @override
  Future<ReminderActionResult> snooze(
    String occurrenceId, {
    int? snoozeMinutes,
    String? note,
  }) async => ReminderActionResult(
    reminder: _occurrence(status: ReminderOccurrenceStatus.snoozed),
    idempotent: false,
  );
  @override
  Future<ReminderActionResult> completeOnBehalf(
    String occurrenceId,
    String note,
  ) async => ReminderActionResult(
    reminder: _occurrence(status: ReminderOccurrenceStatus.completed),
    idempotent: false,
  );
  @override
  Future<ReminderActionResult> cancel(String occurrenceId, String note) async =>
      ReminderActionResult(
        reminder: _occurrence(status: ReminderOccurrenceStatus.canceled),
        idempotent: false,
      );
  @override
  Future<ReminderActionResult> snoozeOnBehalf(
    String occurrenceId,
    String note, {
    int? snoozeMinutes,
  }) async => ReminderActionResult(
    reminder: _occurrence(status: ReminderOccurrenceStatus.snoozed),
    idempotent: false,
  );

  @override
  Future<ReminderTemplate> archiveTemplate(String templateId) async =>
      _template();
  @override
  Future<ReminderTemplate> createTemplate(ReminderTemplateDraft draft) async {
    createdDraft = draft;
    return _template();
  }

  @override
  Future<ReminderTemplate> updateTemplate(
    String templateId,
    Map<String, Object?> changes,
  ) async => _template();
}

ReminderOccurrence _occurrence({
  ReminderOccurrenceStatus status = ReminderOccurrenceStatus.due,
}) => ReminderOccurrence(
  id: 'occurrence-id',
  templateId: 'template-id',
  patientId: 'patient-a',
  title: 'Medication',
  category: ReminderCategory.medication,
  priority: ReminderPriority.high,
  scheduledAt: DateTime.utc(2026, 9, 17, 12),
  dueAt: DateTime.utc(2026, 9, 17, 12, 15),
  status: status,
  snoozeAllowed: true,
  defaultSnoozeMinutes: 10,
  missedAfterMinutes: 30,
);

ReminderTemplate _template() => ReminderTemplate(
  id: 'template-id',
  patientId: 'patient-a',
  createdByUserId: 'caregiver-id',
  title: 'Medication',
  category: ReminderCategory.medication,
  priority: ReminderPriority.high,
  startDate: '2026-09-17',
  startTime: '20:00:00',
  timezone: 'Asia/Manila',
  dueAfterMinutes: 15,
  snoozeAllowed: true,
  defaultSnoozeMinutes: 10,
  missedAfterMinutes: 30,
  notificationChannel: ReminderNotificationChannel.push,
  status: ReminderTemplateStatus.active,
  createdAt: DateTime.utc(2026, 9, 17),
  updatedAt: DateTime.utc(2026, 9, 17),
);

ReminderTemplateDraft _draft() => const ReminderTemplateDraft(
  patientId: 'patient-a',
  title: 'Medication',
  category: ReminderCategory.medication,
  startDate: '2026-09-18',
  startTime: '08:00:00',
);

class _DelayedSource extends _Source {
  final pending = <String, Completer<ReminderPage<ReminderOccurrence>>>{};
  Completer<ReminderActionResult>? action;

  @override
  Future<ReminderPage<ReminderOccurrence>> fetchOccurrences({
    String? patientId,
    List<ReminderOccurrenceStatus> statuses = const [],
    int limit = 100,
    int offset = 0,
  }) {
    final delayed = pending[patientId];
    if (delayed != null) return delayed.future;
    if (patientId == 'patient-b') {
      return Future.value(
        ReminderPage(
          items: const <ReminderOccurrence>[],
          total: 0,
          limit: limit,
          offset: offset,
        ),
      );
    }
    return super.fetchOccurrences(
      patientId: patientId,
      statuses: statuses,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<ReminderPage<ReminderTemplate>> fetchTemplates(
    String patientId, {
    List<ReminderTemplateStatus> statuses = const [],
    int limit = 100,
    int offset = 0,
  }) {
    if (patientId == 'patient-b') {
      return Future.value(
        ReminderPage(
          items: const <ReminderTemplate>[],
          total: 0,
          limit: limit,
          offset: offset,
        ),
      );
    }
    return super.fetchTemplates(
      patientId,
      statuses: statuses,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<ReminderActionResult> complete(String occurrenceId, {String? note}) =>
      action?.future ?? super.complete(occurrenceId, note: note);
}
