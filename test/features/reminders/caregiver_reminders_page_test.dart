import 'package:alera/features/caregiver/domain/models/care_recipient.dart';
import 'package:alera/features/caregiver/domain/models/health_snapshot.dart';
import 'package:alera/design_system/widgets/alera_button.dart';
import 'package:alera/features/reminders/data/reminder_api_data_source.dart';
import 'package:alera/features/reminders/data/reminder_controller.dart';
import 'package:alera/features/reminders/domain/reminder_models.dart';
import 'package:alera/features/reminders/presentation/caregiver_reminders_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 9, 22, 9);

void main() {
  Future<void> pump(WidgetTester tester, _FakeSource source) async {
    final controller = ReminderController(dataSource: source);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: CaregiverRemindersPage(
          controller: controller,
          patients: [_patient('p1', 'Lola Rosa')],
          initialPatientId: 'p1',
          now: () => _now,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows patient name and only the selected day', (tester) async {
    await pump(
      tester,
      _FakeSource([
        _occurrence('a', 'Morning pills', DateTime(2026, 9, 22, 8, 30)),
        _occurrence('b', 'Tomorrow walk', DateTime(2026, 9, 23, 10)),
      ]),
    );

    expect(find.text('Lola Rosa'), findsOneWidget);
    expect(find.text('Tuesday, September 22'), findsOneWidget);
    // Also shown in the summary card's "Next" chip.
    expect(find.text('Morning pills'), findsWidgets);
    expect(find.text('Tomorrow walk'), findsNothing);
    expect(find.byKey(const Key('reminder-patient-picker')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('reminder-day-2026-09-23')));
    await tester.pumpAndSettle();

    expect(find.text('Tomorrow walk'), findsWidgets);
    expect(find.text('Morning pills'), findsNothing);
  });

  testWidgets('today shows summary, NOW marker and collapsed empty hours', (
    tester,
  ) async {
    await pump(
      tester,
      _FakeSource([
        _occurrence('a', 'Morning pills', DateTime(2026, 9, 22, 8, 30)),
        _occurrence('b', 'Evening pills', DateTime(2026, 9, 22, 18)),
      ]),
    );

    expect(find.byKey(const Key('reminder-summary-card')), findsOneWidget);
    expect(find.text('left today'), findsOneWidget);
    expect(find.byKey(const Key('reminder-now-marker')), findsOneWidget);
    expect(find.textContaining('empty hours'), findsWidgets);
    expect(find.text('Tuesday, September 22'), findsOneWidget);
  });

  testWidgets('empty day shows the muted empty state', (tester) async {
    await pump(tester, _FakeSource(const []));

    expect(find.byKey(const Key('reminder-occurrences-empty')), findsOneWidget);
    expect(find.text('No reminders for this day'), findsOneWidget);
  });

  testWidgets('completing asks for a note and calls the controller', (
    tester,
  ) async {
    final source = _FakeSource([
      _occurrence('a', 'Morning pills', DateTime(2026, 9, 22, 8, 30)),
    ]);
    await pump(tester, source);

    await tester.tap(find.byKey(const ValueKey('reminder-complete-a')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('reminder-action-note')),
      'Given at bedside',
    );
    await tester.tap(find.widgetWithText(AleraButton, 'Complete'));
    await tester.pumpAndSettle();

    expect(source.completedOnBehalf, ['a']);
  });

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('create-reminder-button')));
    await tester.pumpAndSettle();
  }

  testWidgets('new reminder opens a drawer with the wheel at the top', (
    tester,
  ) async {
    final source = _FakeSource(const []);
    await pump(tester, source);

    await openSheet(tester);
    expect(find.byKey(const Key('reminder-time-hour')), findsOneWidget);
    expect(find.byKey(const Key('reminder-time-minute')), findsOneWidget);
    expect(find.byKey(const Key('reminder-time-period')), findsOneWidget);
    // Clock is 9:00 AM on the selected day, so a one-off is "now"-ish.
    expect(find.byKey(const Key('reminder-time-until')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('reminder-title-field')),
      'Evening pills',
    );
    await tester.tap(find.byKey(const Key('save-reminder-button')));
    await tester.pumpAndSettle();

    expect(source.createdDraft?.title, 'Evening pills');
    expect(source.createdDraft?.startDate, '2026-09-22');
    expect(source.createdDraft?.startTime, '09:00:00');
    expect(source.createdDraft?.scheduleRule, isNull);
  });

  testWidgets('weekdays and custom repeat set a schedule rule', (tester) async {
    final source = _FakeSource(const []);
    await pump(tester, source);

    await openSheet(tester);
    await tester.enterText(find.byKey(const Key('reminder-title-field')), 'Walk');
    await tester.tap(find.byKey(const Key('reminder-repeat-weekdays')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-reminder-button')));
    await tester.pumpAndSettle();
    expect(
      source.createdDraft?.scheduleRule,
      'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
    );

    await openSheet(tester);
    await tester.enterText(find.byKey(const Key('reminder-title-field')), 'Yoga');
    await tester.tap(find.byKey(const Key('reminder-repeat-custom')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-reminder-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reminder-custom-days-error')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reminder-day-toggle-1')));
    await tester.tap(find.byKey(const ValueKey('reminder-day-toggle-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-reminder-button')));
    await tester.pumpAndSettle();
    expect(source.createdDraft?.scheduleRule, 'FREQ=WEEKLY;BYDAY=MO,WE');
  });

  testWidgets('manage schedules opens the separate page', (tester) async {
    await pump(tester, _FakeSource(const []));

    await tester.tap(find.byTooltip('Manage schedules'));
    await tester.pumpAndSettle();

    expect(find.text('Manage schedules'), findsOneWidget);
    expect(find.byKey(const ValueKey('reminder-template-t1')), findsOneWidget);
  });
}

CareRecipient _patient(String id, String name) => CareRecipient(
  id: id,
  name: name,
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

ReminderOccurrence _occurrence(String id, String title, DateTime at) =>
    ReminderOccurrence(
      id: id,
      templateId: 't1',
      patientId: 'p1',
      title: title,
      category: ReminderCategory.medication,
      priority: ReminderPriority.normal,
      scheduledAt: at,
      dueAt: at.add(const Duration(minutes: 15)),
      status: ReminderOccurrenceStatus.upcoming,
      snoozeAllowed: true,
      defaultSnoozeMinutes: 10,
      missedAfterMinutes: 30,
    );

ReminderTemplate _template() => ReminderTemplate(
  id: 't1',
  patientId: 'p1',
  createdByUserId: 'c1',
  title: 'Morning pills',
  category: ReminderCategory.medication,
  priority: ReminderPriority.normal,
  startDate: '2026-09-22',
  startTime: '08:30:00',
  timezone: 'Asia/Manila',
  dueAfterMinutes: 15,
  snoozeAllowed: true,
  defaultSnoozeMinutes: 10,
  missedAfterMinutes: 30,
  notificationChannel: ReminderNotificationChannel.push,
  status: ReminderTemplateStatus.active,
  createdAt: DateTime(2026, 9, 1),
  updatedAt: DateTime(2026, 9, 1),
);

class _FakeSource implements ReminderDataSource {
  _FakeSource(this.occurrences);

  final List<ReminderOccurrence> occurrences;
  final List<String> completedOnBehalf = [];
  ReminderTemplateDraft? createdDraft;

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
  }) async => ReminderPage(
    items: [_template()],
    total: 1,
    limit: limit,
    offset: offset,
  );

  @override
  Future<ReminderActionResult> completeOnBehalf(
    String occurrenceId,
    String note,
  ) async {
    completedOnBehalf.add(occurrenceId);
    return ReminderActionResult(
      reminder: occurrences.firstWhere((o) => o.id == occurrenceId),
      idempotent: false,
    );
  }

  @override
  Future<ReminderTemplate> createTemplate(ReminderTemplateDraft draft) async {
    createdDraft = draft;
    return _template();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
