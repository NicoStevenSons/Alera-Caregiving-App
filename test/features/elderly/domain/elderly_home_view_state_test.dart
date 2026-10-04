import 'package:alera/features/elderly/domain/elderly_home_view_state.dart';
import 'package:alera/features/elderly/domain/models/elderly_reminder.dart';
import 'package:alera/models/device_status_data.dart';
import 'package:alera/models/heart_rate_data.dart';
import 'package:alera/models/sleep_data.dart';
import 'package:alera/models/spo2_data.dart';
import 'package:alera/models/steps_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('derives monitoring state with safe priority', () {
    expect(
      _state(device: _device()).monitoringState,
      ElderlyMonitoringState.waitingForWatch,
    );
    expect(
      _state(device: _device(connected: true)).monitoringState,
      ElderlyMonitoringState.connected,
    );
    expect(
      _state(device: _device(connected: true, isWorn: false)).monitoringState,
      ElderlyMonitoringState.notWorn,
    );
    expect(
      _state(device: _device(connected: false, isWorn: false)).monitoringState,
      ElderlyMonitoringState.disconnected,
    );
  });

  test('reports each health-data source independently', () {
    final state = _state(
      heartRate: const HeartRateData(
        bpm: 72,
        status: 1,
        measuredAt: '2026-10-04T08:00:00',
      ),
      spo2: const SpO2Data(
        percent: 98,
        status: 2,
        measuredAt: '2026-10-04T08:00:00',
      ),
      steps: const StepsData(
        sessions: [
          StepSessionData(
            stepCount: 500,
            startTime: '2026-10-04T07:00:00',
            endTime: '2026-10-04T08:00:00',
          ),
        ],
      ),
    );

    expect(state.hasHeartRate, isTrue);
    expect(state.hasSpo2, isTrue);
    expect(state.hasActivity, isTrue);
  });

  test('sleep availability only considers the current local day', () {
    final state = _state(
      sleep: const SleepData(
        sessions: [
          SleepSessionData(
            startTime: '2026-10-03T22:00:00',
            endTime: '2026-10-04T06:00:00',
            title: null,
            notes: null,
            stages: [],
          ),
        ],
      ),
    );

    expect(state.hasSleepToday(DateTime(2026, 10, 3, 12)), isTrue);
    expect(state.hasSleepToday(DateTime(2026, 10, 4, 12)), isFalse);
  });

  test('selects earliest active reminder and ignores terminal statuses', () {
    final state = _state(
      reminders: [
        _reminder(
          id: 'completed',
          status: 'COMPLETED',
          scheduledAt: DateTime(2026, 10, 4, 7),
        ),
        _reminder(
          id: 'later',
          status: 'UPCOMING',
          scheduledAt: DateTime(2026, 10, 4, 10),
        ),
        _reminder(
          id: 'next',
          status: 'DUE',
          scheduledAt: DateTime(2026, 10, 4, 8),
        ),
      ],
    );

    expect(state.nextReminder?.occurrenceId, 'next');
  });
}

ElderlyHomeViewState _state({
  HeartRateData heartRate = const HeartRateData(
    bpm: null,
    status: null,
    measuredAt: null,
  ),
  SpO2Data? spo2,
  StepsData? steps,
  SleepData? sleep,
  DeviceStatusData? device,
  List<ElderlyReminder> reminders = const [],
}) {
  return ElderlyHomeViewState(
    heartRate: heartRate,
    spo2: spo2 ?? SpO2Data.empty(),
    steps: steps ?? StepsData.empty(),
    sleep: sleep ?? SleepData.empty(),
    deviceStatus: device ?? DeviceStatusData.empty(),
    reminders: reminders,
    remindersLoading: false,
    remindersError: null,
  );
}

DeviceStatusData _device({bool? connected, bool? isWorn}) {
  return DeviceStatusData(
    batteryPercent: null,
    deviceName: null,
    deviceModel: null,
    connectedToPhone: connected,
    connectedPhoneName: null,
    isCharging: null,
    measuredAt: null,
    isWorn: isWorn,
  );
}

ElderlyReminder _reminder({
  required String id,
  required String status,
  required DateTime scheduledAt,
}) {
  return ElderlyReminder(
    occurrenceId: id,
    templateId: 'template-$id',
    patientId: 'patient',
    title: 'Reminder $id',
    category: 'MEDICATION',
    priority: 'NORMAL',
    scheduledAt: scheduledAt,
    dueAt: scheduledAt.add(const Duration(minutes: 15)),
    status: status,
    snoozeAllowed: true,
    defaultSnoozeMinutes: 10,
  );
}
