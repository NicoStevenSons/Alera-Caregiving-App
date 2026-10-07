import 'package:alera/features/elderly/domain/models/elderly_reminder.dart';
import 'package:alera/features/elderly/presentation/elderly_reminders_page.dart';
import 'package:alera/features/elderly/presentation/patient_reminder_detail_page.dart';
import 'package:alera/features/reminders/data/reminder_api_data_source.dart';
import 'package:alera/features/reminders/domain/reminder_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../reminders/reminder_event_test_support.dart';

void main() {
  late FakeEventsSource events;
  var completed = 0;
  var snoozed = 0;

  Future<void> pumpDetail(WidgetTester tester) async {
    completed = 0;
    snoozed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => PatientReminderDetailPage(
                    reminder: _reminder(),
                    eventsDataSource: events,
                    onComplete: () async => completed++,
                    onSnooze: () async => snoozed++,
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    events = FakeEventsSource([
      event(id: 'a', type: ReminderEventType.created),
      event(
        id: 'b',
        type: ReminderEventType.notificationSent,
        role: ReminderActorRole.system,
        actorName: 'Alera',
      ),
    ]);
  });

  testWidgets('opening a reminder from the list shows its history', (
    tester,
  ) async {
    ElderlyReminder? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElderlyRemindersPage(
              isLoading: false,
              errorMessage: null,
              reminders: [_reminder()],
              busyOccurrenceIds: const {},
              onOpen: (reminder) {
                opened = reminder;
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => PatientReminderDetailPage(
                      reminder: reminder,
                      eventsDataSource: events,
                      onComplete: () async {},
                      onSnooze: () async {},
                    ),
                  ),
                );
              },
              onComplete: (_) async {},
              onSnooze: (_) async {},
              onRetry: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Take medication'));
    await tester.pumpAndSettle();

    expect(opened?.occurrenceId, 'occ-1');
    expect(find.text('Reminder details'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Reminder set up'), findsOneWidget);
    expect(find.text('You were reminded'), findsOneWidget);
    expect(events.offsets, [0]);
  });

  testWidgets('has no caregiver-only controls', (tester) async {
    await pumpDetail(tester);

    expect(find.text('Timeline'), findsNothing);
    expect(find.byKey(const Key('reminder-action-complete')), findsNothing);
    expect(find.byKey(const Key('reminder-action-cancel')), findsNothing);
    expect(find.text('Cancel this reminder'), findsNothing);
    expect(find.text('Mark complete'), findsNothing);
    expect(find.text('Load more'), findsNothing);
  });

  testWidgets('Complete still works and closes the page', (tester) async {
    await pumpDetail(tester);

    await tester.tap(find.text('Complete'));
    await tester.pumpAndSettle();

    expect(completed, 1);
    expect(find.text('Reminder details'), findsNothing);
  });

  testWidgets('Snooze still works and closes the page', (tester) async {
    await pumpDetail(tester);

    await tester.tap(find.text('Snooze 10 min'));
    await tester.pumpAndSettle();

    expect(snoozed, 1);
    expect(find.text('Reminder details'), findsNothing);
  });

  testWidgets('history failure is retryable and does not block actions', (
    tester,
  ) async {
    events.failures.add(const ReminderApiFailure('Offline'));
    await pumpDetail(tester);

    expect(find.text('We couldn’t load the history.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('reminder-timeline-retry')));
    await tester.pumpAndSettle();
    expect(find.text('Reminder set up'), findsOneWidget);
  });

  testWidgets('empty history uses plain wording', (tester) async {
    events = FakeEventsSource(const []);
    await pumpDetail(tester);
    expect(
      find.text('Nothing has happened with this reminder yet.'),
      findsOneWidget,
    );
  });

  testWidgets('without a history source the page still shows the card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PatientReminderDetailPage(
          reminder: _reminder(),
          onComplete: () async {},
          onSnooze: () async {},
        ),
      ),
    );
    expect(find.text('Take medication'), findsOneWidget);
    expect(find.text('History'), findsNothing);
  });
}

ElderlyReminder _reminder() => ElderlyReminder(
  occurrenceId: 'occ-1',
  templateId: 'tpl-1',
  patientId: 'p1',
  title: 'Take medication',
  category: 'MEDICATION',
  priority: 'NORMAL',
  scheduledAt: DateTime(2026, 10, 7, 8),
  dueAt: DateTime(2026, 10, 7, 8, 15),
  status: 'DUE',
  snoozeAllowed: true,
  defaultSnoozeMinutes: 10,
);
