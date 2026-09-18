enum AleraNotificationKind {
  dueReminder,
  missedReminder,
  nudge,
  healthAlert,
  deviceStatus,
  general,
}

class AleraNotificationPresentation {
  const AleraNotificationPresentation({
    required this.kind,
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    required this.fallbackTitle,
    required this.fallbackBody,
  });

  final AleraNotificationKind kind;
  final String channelId;
  final String channelName;
  final String channelDescription;
  final String fallbackTitle;
  final String fallbackBody;

  bool get hasReminderActions => kind == AleraNotificationKind.dueReminder;

  static AleraNotificationPresentation fromData(Map<String, dynamic> data) {
    return switch (data['type']) {
      'REMINDER_DUE' => dueReminder,
      'REMINDER' => missedReminder,
      'NUDGE' => nudge,
      'ALERT' => healthAlert,
      'DEVICE_STATUS' => deviceStatus,
      _ => general,
    };
  }

  static const dueReminder = AleraNotificationPresentation(
    kind: AleraNotificationKind.dueReminder,
    channelId: 'alera_patient_reminders_v2',
    channelName: 'Patient reminders',
    channelDescription: 'Time-sensitive reminders for patients',
    fallbackTitle: 'Alera reminder',
    fallbackBody: "It's time for this reminder.",
  );

  static const missedReminder = AleraNotificationPresentation(
    kind: AleraNotificationKind.missedReminder,
    channelId: 'alera_caregiver_reminders_v2',
    channelName: 'Caregiver reminder alerts',
    channelDescription: 'Missed-reminder alerts for caregivers',
    fallbackTitle: 'Missed reminder',
    fallbackBody: 'A patient missed a reminder.',
  );

  static const nudge = AleraNotificationPresentation(
    kind: AleraNotificationKind.nudge,
    channelId: 'alera_nudges_v2',
    channelName: 'Alera nudges',
    channelDescription: 'Caregiver nudges for patients',
    fallbackTitle: 'Alera reminder',
    fallbackBody: 'Your caregiver sent you a reminder.',
  );

  static const healthAlert = AleraNotificationPresentation(
    kind: AleraNotificationKind.healthAlert,
    channelId: 'alera_alerts_v2',
    channelName: 'Alera health alerts',
    channelDescription: 'Time-sensitive caregiver health alerts',
    fallbackTitle: 'Alera health alert',
    fallbackBody: 'A new alert needs your attention.',
  );

  static const deviceStatus = AleraNotificationPresentation(
    kind: AleraNotificationKind.deviceStatus,
    channelId: 'alera_device_status_v2',
    channelName: 'Device status alerts',
    channelDescription: 'Connectivity and battery alerts for monitored devices',
    fallbackTitle: 'Device status changed',
    fallbackBody: 'A monitored device needs your attention.',
  );

  static const general = AleraNotificationPresentation(
    kind: AleraNotificationKind.general,
    channelId: 'alera_general_v2',
    channelName: 'Alera notifications',
    channelDescription: 'General Alera notifications',
    fallbackTitle: 'Alera',
    fallbackBody: 'You have a new notification.',
  );
}
