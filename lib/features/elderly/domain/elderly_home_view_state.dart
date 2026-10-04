import '../../../models/device_status_data.dart';
import '../../../models/heart_rate_data.dart';
import '../../../models/sleep_data.dart';
import '../../../models/spo2_data.dart';
import '../../../models/steps_data.dart';
import 'models/elderly_reminder.dart';

enum ElderlyMonitoringState {
  waitingForWatch,
  connected,
  disconnected,
  notWorn,
}

class ElderlyHomeViewState {
  const ElderlyHomeViewState({
    required this.heartRate,
    required this.spo2,
    required this.steps,
    required this.sleep,
    required this.deviceStatus,
    required this.reminders,
    required this.remindersLoading,
    required this.remindersError,
  });

  final HeartRateData heartRate;
  final SpO2Data spo2;
  final StepsData steps;
  final SleepData sleep;
  final DeviceStatusData deviceStatus;
  final List<ElderlyReminder> reminders;
  final bool remindersLoading;
  final String? remindersError;

  ElderlyMonitoringState get monitoringState {
    if (deviceStatus.connectedToPhone == false) {
      return ElderlyMonitoringState.disconnected;
    }
    if (deviceStatus.isWorn == false) {
      return ElderlyMonitoringState.notWorn;
    }
    if (deviceStatus.connectedToPhone == true) {
      return ElderlyMonitoringState.connected;
    }
    return ElderlyMonitoringState.waitingForWatch;
  }

  bool get hasHeartRate => (heartRate.bpm ?? 0) > 0;
  bool get hasSpo2 => (spo2.percent ?? 0) > 0;
  bool get hasActivity => steps.sessions.isNotEmpty;

  bool hasSleepToday(DateTime now) {
    final localDay = now.toLocal();

    return sleep.sessions.any((session) {
      final start = DateTime.tryParse(session.startTime)?.toLocal();
      return start != null &&
          start.year == localDay.year &&
          start.month == localDay.month &&
          start.day == localDay.day;
    });
  }

  ElderlyReminder? get nextReminder {
    const activeStatuses = <String>{'UPCOMING', 'DUE', 'SNOOZED'};

    final active =
        reminders
            .where((reminder) => activeStatuses.contains(reminder.status))
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return active.isEmpty ? null : active.first;
  }
}
