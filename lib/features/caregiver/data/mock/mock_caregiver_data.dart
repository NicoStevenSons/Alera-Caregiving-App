import '../../domain/models/care_recipient.dart';
import '../../domain/models/caregiver_alert.dart';
import '../../domain/models/caregiver_reminder.dart';
import '../../domain/models/health_snapshot.dart';

abstract final class MockCaregiverData {
  static final List<CareRecipient> careRecipients = [
    CareRecipient(
      id: 'maria-santos',
      name: 'Maria Santos',
      relationshipLabel: 'Mother • Under your care',
      status: CareStatus.needsAttention,
      alertCount: 2,
      reminderCount: 3,
      quickMessages: const [
        'Love you ❤️',
        'How are you? 😊',
        'Did you take meds? 💊',
        'Checking in 👋',
        'Call me 📞',
      ],
      healthSnapshot: HealthSnapshot(
        heartRateBpm: 62,
        spo2Percent: 98,
        steps: 1204,
        stressLabel: 'Low Stress',
        sleepDuration: const Duration(hours: 5, minutes: 20),
        careRiskScore: 42,
        careRiskLabel: 'Moderate Risk',
        lastCheckIn: DateTime(2026, 9, 3, 10, 3),
        devices: const [
          MonitoringDevice(
            name: 'Phone',
            batteryPercent: 78,
            connectionStatus: MonitoringDeviceConnectionStatus.connected,
          ),
          MonitoringDevice(
            name: 'Watch',
            batteryPercent: 67,
            connectionStatus: MonitoringDeviceConnectionStatus.connected,
          ),
        ],
      ),
    ),
    CareRecipient(
      id: 'geraldine-laggui',
      name: 'Geraldine Laggui',
      relationshipLabel: 'Under your care',
      status: CareStatus.stable,
      alertCount: 0,
      reminderCount: 2,
      quickMessages: const ['How are you? 😊', 'Checking in 👋', 'Call me 📞'],
      healthSnapshot: HealthSnapshot(
        heartRateBpm: null,
        spo2Percent: null,
        steps: null,
        stressLabel: 'Low Stress',
        sleepDuration: const Duration(hours: 7, minutes: 5),
        careRiskScore: 18,
        careRiskLabel: 'Low Risk',
        lastCheckIn: DateTime(2026, 9, 3, 9, 45),
        devices: const [
          MonitoringDevice(
            name: 'Phone',
            batteryPercent: 78,
             connectionStatus: MonitoringDeviceConnectionStatus.connected,
          ),
          MonitoringDevice(
            name: 'Watch',
            batteryPercent: 67,
             connectionStatus: MonitoringDeviceConnectionStatus.connected,
          ),
        ],
      ),
    ),
  ];

  static final List<CaregiverAlert> alerts = [
    CaregiverAlert(
      id: 'maria-high-heart-rate',
      careRecipientId: 'maria-santos',
      title: 'High Heart Rate',
      description:
          'Maria’s heart rate remained above the alert threshold for 5 minutes.',
      severity: CaregiverAlertSeverity.warning,
      metric: CaregiverAlertMetric.heartRate,
      status: CaregiverAlertStatus.active,
      reading: 105,
      threshold: 100,
      unit: 'BPM',
      triggerDuration: const Duration(minutes: 5),
      detectedAt: DateTime(2026, 9, 3, 10, 3),
      timeline: [
        AlertTimelineEntry(
          occurredAt: DateTime(2026, 9, 3, 10, 3),
          title: 'Alert triggered',
          description: 'Heart rate detected at 105 BPM',
        ),
      ],
    ),
    CaregiverAlert(
      id: 'geraldine-low-watch-battery',
      careRecipientId: 'geraldine-laggui',
      title: 'Low Watch Battery',
      description: 'Watch battery has reached 12%.',
      severity: CaregiverAlertSeverity.warning,
      metric: CaregiverAlertMetric.watchBattery,
      status: CaregiverAlertStatus.acknowledged,
      reading: 12,
      threshold: null,
      unit: '%',
      triggerDuration: null,
      detectedAt: DateTime(2026, 9, 3, 9, 58),
      timeline: const [],
    ),
  ];

  static final List<CaregiverReminder> reminders = [
    CaregiverReminder(
      id: 'maria-medication',
      careRecipientId: 'maria-santos',
      title: 'Medication',
      description: 'Scheduled BP medication',
      scheduledAt: DateTime(2026, 9, 3, 10, 3),
      status: CaregiverReminderStatus.missed,
    ),
    CaregiverReminder(
      id: 'maria-monitoring',
      careRecipientId: 'maria-santos',
      title: 'Monitoring',
      description: 'Blood Pressure Check mo si Mama',
      scheduledAt: DateTime(2026, 9, 3, 16),
      status: CaregiverReminderStatus.upcoming,
    ),
  ];
}
