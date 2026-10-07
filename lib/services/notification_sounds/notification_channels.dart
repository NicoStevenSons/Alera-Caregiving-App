import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_sound_catalog.dart';

/// Legacy channels kept so payloads/devices from older builds still work.
/// They are never edited or deleted here (the user may have customised them).
const String legacyAlertsChannelId = 'alera_alerts';
const String legacyPatientRemindersChannelId = 'alera_patient_reminders_v2';
const String legacyNudgesChannelId = 'alera_nudges';

AndroidNotificationChannel alertChannel(AlertSoundCategory category) {
  return AndroidNotificationChannel(
    category.channelId,
    category.channelName,
    description: category.description,
    importance: category.urgent ? Importance.max : Importance.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound(category.rawResource),
    enableVibration: true,
  );
}

AndroidNotificationChannel reminderChannel(ReminderSound sound) {
  return AndroidNotificationChannel(
    sound.channelId,
    'Reminders · ${sound.label}',
    description: 'Reminder notifications (${sound.label.toLowerCase()})',
    // Silent reminders must still appear, just without a heads-up sound.
    importance: sound == ReminderSound.silent
        ? Importance.defaultImportance
        : Importance.max,
    playSound: sound.playsSound,
    sound: sound.rawResource == null
        ? null
        : RawResourceAndroidNotificationSound(sound.rawResource),
    enableVibration: sound.vibrates,
  );
}

/// Creates every fixed alert channel plus the legacy ones. Safe to call on
/// every start and from the background-message isolate.
Future<void> ensureAlertChannels(
  AndroidFlutterLocalNotificationsPlugin? android,
) async {
  if (android == null) return;
  for (final AlertSoundCategory category in AlertSoundCategory.values) {
    await android.createNotificationChannel(alertChannel(category));
  }
  await android.createNotificationChannel(
    const AndroidNotificationChannel(
      legacyAlertsChannelId,
      'Alera alerts',
      description: 'Caregiver health alerts',
      importance: Importance.high,
    ),
  );
  await android.createNotificationChannel(
    const AndroidNotificationChannel(
      legacyNudgesChannelId,
      'Alera reminders',
      description: 'Caregiver reminders for patients',
      importance: Importance.high,
    ),
  );
}

/// Creates (once) the channel for the chosen reminder sound. Only the
/// selected sound's channel is created, so the system settings list does not
/// fill with unused channels.
Future<void> ensureReminderChannel(
  AndroidFlutterLocalNotificationsPlugin? android,
  ReminderSound sound,
) async {
  if (android == null) return;
  await android.createNotificationChannel(reminderChannel(sound));
}

/// Android details for a fixed-sound alert. [extra] lets callers keep their
/// existing icon / style / visibility / category settings.
AndroidNotificationDetails alertAndroidDetails(
  AlertSoundCategory category, {
  String? icon,
  AndroidBitmap<Object>? largeIcon,
  StyleInformation? styleInformation,
  NotificationVisibility? visibility,
  AndroidNotificationCategory? notificationCategory,
}) {
  return AndroidNotificationDetails(
    category.channelId,
    category.channelName,
    channelDescription: category.description,
    importance: category.urgent ? Importance.max : Importance.high,
    priority: category.urgent ? Priority.max : Priority.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound(category.rawResource),
    enableVibration: true,
    icon: icon,
    largeIcon: largeIcon,
    styleInformation: styleInformation,
    visibility: visibility,
    category: notificationCategory,
  );
}

/// Android details for an ordinary reminder with the user's chosen sound.
AndroidNotificationDetails reminderAndroidDetails(
  ReminderSound sound, {
  String? icon,
  AndroidBitmap<Object>? largeIcon,
  List<AndroidNotificationAction>? actions,
  AndroidNotificationCategory? notificationCategory,
  bool fullScreenIntent = false,
}) {
  return AndroidNotificationDetails(
    sound.channelId,
    'Reminders · ${sound.label}',
    channelDescription: 'Reminder notifications (${sound.label.toLowerCase()})',
    importance: sound == ReminderSound.silent
        ? Importance.defaultImportance
        : Importance.max,
    priority: sound == ReminderSound.silent ? Priority.defaultPriority : Priority.max,
    playSound: sound.playsSound,
    sound: sound.rawResource == null
        ? null
        : RawResourceAndroidNotificationSound(sound.rawResource),
    enableVibration: sound.vibrates,
    icon: icon,
    largeIcon: largeIcon,
    actions: actions,
    category: notificationCategory,
    fullScreenIntent: fullScreenIntent,
  );
}
