import 'package:alera/features/caregiver/domain/models/care_recipient.dart';
import 'package:alera/features/caregiver/domain/models/health_snapshot.dart';
import 'package:alera/features/reminders/data/reminder_api_data_source.dart';
import 'package:alera/features/reminders/data/reminder_controller.dart';
import 'package:alera/features/reminders/domain/reminder_event.dart';
import 'package:alera/features/reminders/domain/reminder_models.dart';
import 'package:alera/features/reminders/presentation/caregiver_reminders_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reminder_event_test_support.dart';

final _now = DateTime(2026, 9, 22, 9);

void main() {
  late _Source source;
  late FakeEventsSource events;

  Future<void> pump(
    WidgetTester tester, {
    ReminderOccurrence? reminder,
  }) async {
    source = _Source([reminder ?? occurrence()]);
    events = FakeEventsSource([
      event(id: 'a', type: ReminderEventType.created),
      event(id: 'b', type: ReminderEventType.notificationSent),
    ]);
    final controller = ReminderController(dataSource: source);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: CaregiverRemindersPage(
          controller: controller,
          patients: [_patient()],
          initialPatientId: 'p1',
          eventsDataSource: events,
          now: () => _now,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openDetail(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('reminder-occurrence-occ-1')));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a reminder opens its detail with a Timeline', (
    tester,
  ) async {
    await pump(tester);
    await openDetail(tester);

    expect(find.byKey(const Key('reminder-detail')), findsOneWidget);
    expect(find.byKey(const Key('reminder-detail-title')), findsOneWidget);
    expect(find.text('Morning pills'), findsWidgets);
    expect(find.text('Medication'), findsOneWidget);
    expect(find.text('Take with water'), findsOneWidget);
    expect(find.text('Scheduled'), findsOneWidget);
    expect(find.text('Due'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Created'), findsOneWidget);
    expect(find.text('Notification sent'), findsOneWidget);
    expect(events.offsets, [0]);
  });

  testWidgets('a completed reminder still opens its history, without actions', (
    tester,
  ) async {
    await pump(
      tester,
      reminder: occurrence(status: ReminderOccurrenceStatus.completed),
    );
    await openDetail(tester);

    expect(find.text('Timeline'), findsOneWidget);
    expect(find.byKey(const Key('reminder-action-complete')), findsNothing);
    expect(find.byKey(const Key('reminder-action-cancel')), findsNothing);
  });

  testWidgets('Complete still asks for a note and reloads the timeline', (
    tester,
  ) async {
    await pump(tester);
    await openDetail(tester);

    await tester.tap(find.byKey(const Key('reminder-action-complete')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('reminder-action-note')),
      'Given at bedside',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Complete'));
    await tester.pumpAndSettle();

    expect(source.completedOnBehalf, ['occ-1']);
    expect(events.offsets, [0, 0]);
  });

  testWidgets('Snooze still asks for a note', (tester) async {
    await pump(tester);
    await openDetail(tester);

    await tester.tap(find.byKey(const Key('reminder-action-snooze')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('reminder-action-note')),
      'Needs more time',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Snooze'));
    await tester.pumpAndSettle();

    expect(source.snoozed, ['occ-1']);
  });

  testWidgets('Cancel still asks for a reason', (tester) async {
    await pump(tester);
    await openDetail(tester);

    await tester.tap(find.byKey(const Key('reminder-action-cancel')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('reminder-action-note')),
      'Not needed',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel reminder'));
    await tester.pumpAndSettle();

    expect(source.canceled, ['occ-1']);
  });

  testWidgets('timeline failure on the detail page can be retried', (
    tester,
  ) async {
    await pump(tester);
    events.failures.add(const ReminderApiFailure('Offline'));
    await openDetail(tester);

    expect(find.byKey(const Key('reminder-timeline-error')), findsOneWidget);
    await tester.tap(find.byKey(const Key('reminder-timeline-retry')));
    await tester.pumpAndSettle();
    expect(find.text('Created'), findsOneWidget);
  });
}

CareRecipient _patient() => CareRecipient(
  id: 'p1',
  name: 'Lola Rosa',
  relationshipLabel: 'Mother',
  backendBacked: true,
  status: CareStatus.stable,
  alertCount: 0,
  reminderCount: 0,
  quickMessages: const [],
  healthSnapshot: HealthSnapshot(
    heartRateBpm: null,
    spo2Percent: null,
    steps: null,
    stressLabel: 'Low',
    sleepDuration: Duration.zero,
    careRiskScore: 0,
    careRiskLabel: 'Low',
    lastCheckIn: DateTime(2026, 9, 22),
    devices: const [],
  ),
);

class _Source implements ReminderDataSource {
  _Source(this.occurrences);
  final List<ReminderOccurrence> occurrences;
  final List<String> completedOnBehalf = [];
  final List<String> snoozed = [];
  final List<String> canceled = [];

  ReminderActionResult _result(String id) => ReminderActionResult(
    reminder: occurrences.firstWhere((o) => o.id == id),
    idempotent: false,
  );

  @override
  Future<ReminderPage<ReminderOccurrence>> fetchOccurrences({
    String? patientId,
    List<ReminderOccurrenceStatus> statuses = const [],
    int limit = 100,
    int offset = 0,
  }) async => ReminderPage(
    items: occurrences,
    total: occurrences.length,
    limit: limit,
    offset: offset,
  );

  @override
  Future<ReminderPage<ReminderTemplate>> fetchTemplates(
    String patientId, {
    List<ReminderTemplateStatus> statuses = const [],
    int limit = 100,
    int offset = 0,
  }) async => ReminderPage(items: const [], total: 0, limit: limit, offset: 0);

  @override
  Future<ReminderActionResult> completeOnBehalf(
    String occurrenceId,
    String note,
  ) async {
    completedOnBehalf.add(occurrenceId);
    return _result(occurrenceId);
  }

  @override
  Future<ReminderActionResult> snoozeOnBehalf(
    String occurrenceId,
    String note, {
    int? snoozeMinutes,
  }) async {
    snoozed.add(occurrenceId);
    return _result(occurrenceId);
  }

  @override
  Future<ReminderActionResult> cancel(String occurrenceId, String note) async {
    canceled.add(occurrenceId);
    return _result(occurrenceId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
