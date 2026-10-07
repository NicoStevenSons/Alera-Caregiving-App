import 'dart:async';

import 'package:alera/features/reminders/data/reminder_api_data_source.dart';
import 'package:alera/features/reminders/data/reminder_timeline_controller.dart';
import 'package:alera/features/reminders/domain/reminder_event.dart';
import 'package:alera/features/reminders/presentation/widgets/reminder_history_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reminder_event_test_support.dart';

void main() {
  Future<ReminderTimelineController> pump(
    WidgetTester tester,
    FakeEventsSource source, {
    bool elderly = false,
    int pageSize = 50,
    bool settle = true,
  }) async {
    final controller = ReminderTimelineController(
      dataSource: source,
      occurrenceId: 'occ-1',
      pageSize: pageSize,
    );
    addTearDown(controller.dispose);
    controller.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReminderHistorySection(
              controller: controller,
              elderly: elderly,
            ),
          ),
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('shows a loading indicator until the first page arrives', (
    tester,
  ) async {
    final source = FakeEventsSource([event()]);
    source.gate = _gate();
    await pump(tester, source, settle: false);
    await tester.pump();

    expect(find.byKey(const Key('reminder-timeline-loading')), findsOneWidget);
    expect(find.text('Created'), findsNothing);

    source.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reminder-timeline-loading')), findsNothing);
    expect(find.text('Created'), findsOneWidget);
  });

  testWidgets('renders events oldest first with label, time and actor', (
    tester,
  ) async {
    await pump(
      tester,
      FakeEventsSource([
        event(id: 'a', type: ReminderEventType.created),
        event(
          id: 'b',
          type: ReminderEventType.notificationSent,
          role: ReminderActorRole.system,
          actorName: null,
          metadata: {'audience': 'PATIENT', 'channel': 'PUSH'},
        ),
        event(
          id: 'c',
          type: ReminderEventType.completedOnBehalf,
          note: 'Given at bedside',
        ),
      ]),
    );

    final created = tester.getTopLeft(find.text('Created')).dy;
    final sent = tester.getTopLeft(find.text('Notification sent')).dy;
    final done = tester.getTopLeft(find.text('Completed by caregiver')).dy;
    expect(created, lessThan(sent));
    expect(sent, lessThan(done));

    expect(find.textContaining('Maria Santos'), findsNWidgets(2));
    expect(find.textContaining('Oct 7, 2026'), findsNWidgets(3));
    expect(find.text('Sent to patient · Push notification'), findsOneWidget);
    expect(find.text('Given at bedside'), findsOneWidget);
    expect(find.textContaining('Alera'), findsOneWidget);
  });

  testWidgets('snoozed events show the snoozed-until time, no raw JSON', (
    tester,
  ) async {
    await pump(
      tester,
      FakeEventsSource([
        event(
          type: ReminderEventType.snoozed,
          metadata: {
            'snoozed_until': '2026-10-07T07:10:00Z',
            'internal_flag': 'x',
          },
        ),
      ]),
    );
    expect(find.text('Snoozed'), findsOneWidget);
    expect(find.textContaining('Until '), findsOneWidget);
    expect(find.textContaining('internal_flag'), findsNothing);
    expect(find.textContaining('{'), findsNothing);
  });

  testWidgets('an unknown event type renders a generic entry', (tester) async {
    await pump(
      tester,
      FakeEventsSource([
        event(type: ReminderEventType.unknown, rawType: 'ESCALATED'),
      ]),
    );
    expect(find.text('Escalated'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty history shows the empty state', (tester) async {
    await pump(tester, FakeEventsSource(const []));
    expect(find.byKey(const Key('reminder-timeline-empty')), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
  });

  testWidgets('failure shows a retry that reloads', (tester) async {
    final source = FakeEventsSource([event()])
      ..failures.add(const ReminderApiFailure('Offline'));
    await pump(tester, source);

    expect(find.byKey(const Key('reminder-timeline-error')), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reminder-timeline-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reminder-timeline-error')), findsNothing);
    expect(find.text('Created'), findsOneWidget);
  });

  testWidgets('a 404 has no retry button', (tester) async {
    final source = FakeEventsSource(const [])
      ..failures.add(const ReminderApiFailure('Gone', statusCode: 404));
    await pump(tester, source);
    expect(find.byKey(const Key('reminder-timeline-error')), findsOneWidget);
    expect(find.byKey(const Key('reminder-timeline-retry')), findsNothing);
  });

  testWidgets('Load more appears when total exceeds the shown events', (
    tester,
  ) async {
    final source = FakeEventsSource([
      event(id: 'a', type: ReminderEventType.created),
      event(id: 'b', type: ReminderEventType.notificationSent),
      event(id: 'c', type: ReminderEventType.completed),
    ]);
    await pump(tester, source, pageSize: 2);

    expect(find.text('Completed'), findsNothing);
    expect(
      find.byKey(const Key('reminder-timeline-load-more')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('reminder-timeline-load-more')));
    await tester.pumpAndSettle();

    expect(find.text('Completed'), findsOneWidget);
    expect(find.byKey(const Key('reminder-timeline-load-more')), findsNothing);
    expect(source.offsets, [0, 2]);
    expect(
      tester.getTopLeft(find.text('Notification sent')).dy,
      lessThan(tester.getTopLeft(find.text('Completed')).dy),
    );
  });

  testWidgets('no Load more when everything is already shown', (tester) async {
    await pump(tester, FakeEventsSource([event(id: 'a'), event(id: 'b')]));
    expect(find.byKey(const Key('reminder-timeline-load-more')), findsNothing);
  });

  testWidgets('elderly wording is friendly and non-technical', (tester) async {
    await pump(
      tester,
      FakeEventsSource([
        event(
          id: 'a',
          type: ReminderEventType.notificationSent,
          role: ReminderActorRole.system,
          actorName: 'Alera',
          metadata: {'audience': 'PATIENT', 'channel': 'PUSH'},
        ),
        event(
          id: 'b',
          type: ReminderEventType.snoozed,
          role: ReminderActorRole.patient,
          actorName: 'Lola Rosa',
          metadata: {'snoozed_until': '2026-10-07T07:10:00Z'},
        ),
        event(
          id: 'c',
          type: ReminderEventType.completedOnBehalf,
          actorName: 'Maria Santos',
        ),
      ]),
      elderly: true,
    );

    expect(find.text('History'), findsOneWidget);
    expect(find.text('Timeline'), findsNothing);
    expect(find.text('You were reminded'), findsOneWidget);
    expect(find.text('You snoozed it'), findsOneWidget);
    expect(find.text('Marked done for you'), findsOneWidget);
    expect(find.textContaining('· Alera'), findsOneWidget);
    expect(find.textContaining('· You'), findsOneWidget);
    expect(find.textContaining('Push'), findsNothing);
    expect(find.textContaining('metadata'), findsNothing);
    expect(find.textContaining('occurrence'), findsNothing);
  });

  testWidgets('elderly empty and error states stay plain', (tester) async {
    await pump(tester, FakeEventsSource(const []), elderly: true);
    expect(
      find.text('Nothing has happened with this reminder yet.'),
      findsOneWidget,
    );

    final source = FakeEventsSource(const [])
      ..failures.add(const ReminderApiFailure('Timed out waiting'));
    await pump(tester, source, elderly: true);
    expect(find.text('We couldn’t load the history.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}

Completer<void> _gate() => Completer<void>();
