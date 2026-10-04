import 'package:alera/Services/upload_queue_service.dart';
import 'package:alera/features/elderly/domain/elderly_home_view_state.dart';
import 'package:alera/features/elderly/domain/models/elderly_reminder.dart';
import 'package:alera/features/elderly/presentation/elderly_home_page.dart';
import 'package:alera/models/device_status_data.dart';
import 'package:alera/models/heart_rate_data.dart';
import 'package:alera/models/sleep_data.dart';
import 'package:alera/models/spo2_data.dart';
import 'package:alera/models/steps_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows honest initial monitoring and reminder states', (
    tester,
  ) async {
    await _pumpHome(tester, _state());

    expect(find.text('Waiting for smartwatch'), findsOneWidget);
    expect(find.byKey(const Key('elderly-request-help')), findsOneWidget);
    expect(
      find.byKey(const Key('elderly-next-reminder-empty')),
      findsOneWidget,
    );
  });

  testWidgets('shows reminder error separately and retries', (tester) async {
    var retries = 0;

    await _pumpHome(
      tester,
      _state(remindersError: 'Please sign in again.'),
      onRetry: () => retries++,
    );

    expect(
      find.byKey(const Key('elderly-next-reminder-error')),
      findsOneWidget,
    );
    expect(find.text('Please sign in again.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('elderly-retry-reminders')));
    await tester.pump();

    expect(retries, 1);
  });

  testWidgets('shows and opens the earliest active reminder', (tester) async {
    ElderlyReminder? opened;
    final reminder = _reminder();

    await _pumpHome(
      tester,
      _state(reminders: [reminder]),
      onReminderTap: (value) => opened = value,
    );

    expect(find.byKey(const Key('elderly-next-reminder')), findsOneWidget);
    expect(find.text('Take medicine'), findsOneWidget);

    await tester.tap(find.byKey(const Key('elderly-next-reminder')));
    await tester.pump();

    expect(opened?.occurrenceId, reminder.occurrenceId);
  });
}

Future<void> _pumpHome(
  WidgetTester tester,
  ElderlyHomeViewState state, {
  VoidCallback? onRetry,
  ValueChanged<ElderlyReminder>? onReminderTap,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ElderlyHomePage(
          state: state,
          uploadQueueService: UploadQueueService(),
          onRetryReminders: onRetry,
          onReminderTap: onReminderTap,
        ),
      ),
    ),
  );
  await tester.pump();
}

ElderlyHomeViewState _state({
  List<ElderlyReminder> reminders = const [],
  String? remindersError,
}) {
  return ElderlyHomeViewState(
    heartRate: const HeartRateData(bpm: null, status: null, measuredAt: null),
    spo2: SpO2Data.empty(),
    steps: StepsData.empty(),
    sleep: SleepData.empty(),
    deviceStatus: DeviceStatusData.empty(),
    reminders: reminders,
    remindersLoading: false,
    remindersError: remindersError,
  );
}

ElderlyReminder _reminder() {
  return ElderlyReminder(
    occurrenceId: 'next-reminder',
    templateId: 'template',
    patientId: 'patient',
    title: 'Take medicine',
    category: 'MEDICATION',
    priority: 'NORMAL',
    scheduledAt: DateTime(2026, 10, 4, 8),
    dueAt: DateTime(2026, 10, 4, 8, 15),
    status: 'UPCOMING',
    snoozeAllowed: true,
    defaultSnoozeMinutes: 10,
  );
}
