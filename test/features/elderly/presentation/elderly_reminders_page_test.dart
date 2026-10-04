import 'package:alera/features/elderly/domain/models/elderly_reminder.dart';
import 'package:alera/features/elderly/presentation/elderly_reminders_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loading takes priority over stale error and reminders', (
    tester,
  ) async {
    await _pump(
      tester,
      isLoading: true,
      errorMessage: 'Offline',
      reminders: [_reminder()],
    );

    expect(find.byKey(const Key('elderly-reminders-loading')), findsOneWidget);
    expect(find.byKey(const Key('elderly-reminders-error')), findsNothing);
    expect(find.text('Take medication'), findsNothing);
  });

  testWidgets('error explains failure and retry calls the loader', (
    tester,
  ) async {
    var retries = 0;

    await _pump(
      tester,
      errorMessage: 'Please sign in again.',
      onRetry: () => retries++,
    );

    expect(find.byKey(const Key('elderly-reminders-error')), findsOneWidget);
    expect(find.text('Unable to load reminders'), findsOneWidget);
    expect(find.text('Please sign in again.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('elderly-reminders-retry')));

    expect(retries, 1);
  });

  testWidgets('empty response is distinct from loading and failure', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byKey(const Key('elderly-reminders-empty')), findsOneWidget);
    expect(find.text('No reminders right now'), findsOneWidget);
    expect(find.byKey(const Key('elderly-reminders-loading')), findsNothing);
    expect(find.byKey(const Key('elderly-reminders-error')), findsNothing);
  });

  testWidgets('successful response renders reminder content', (tester) async {
    await _pump(tester, reminders: [_reminder()]);

    expect(find.text('Take medication'), findsOneWidget);
    expect(find.byKey(const Key('elderly-reminders-empty')), findsNothing);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  bool isLoading = false,
  String? errorMessage,
  List<ElderlyReminder> reminders = const [],
  VoidCallback? onRetry,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ElderlyRemindersPage(
          isLoading: isLoading,
          errorMessage: errorMessage,
          reminders: reminders,
          busyOccurrenceIds: const {},
          onOpen: (_) {},
          onComplete: (_) async {},
          onSnooze: (_) async {},
          onRetry: onRetry ?? () {},
        ),
      ),
    ),
  );
}

ElderlyReminder _reminder() {
  return ElderlyReminder(
    occurrenceId: 'occurrence',
    templateId: 'template',
    patientId: 'patient',
    title: 'Take medication',
    category: 'MEDICATION',
    priority: 'NORMAL',
    scheduledAt: DateTime(2026, 10, 4, 8),
    dueAt: DateTime(2026, 10, 4, 8, 15),
    status: 'DUE',
    snoozeAllowed: true,
    defaultSnoozeMinutes: 10,
  );
}
