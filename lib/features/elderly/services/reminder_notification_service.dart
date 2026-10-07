import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../services/notification_sounds/reminder_sound_store.dart';
import '../../../services/notification_sounds/notification_channels.dart';
import '../../../services/notification_sounds/notification_sound_catalog.dart';
import '../domain/models/elderly_reminder.dart';

class ReminderNotificationService {
  ReminderNotificationService._();

  static final ReminderNotificationService instance =
      ReminderNotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings: settings);

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();

    await androidPlugin?.requestExactAlarmsPermission();
  }

  Future<void> scheduleReminder(ElderlyReminder reminder) async {
    final DateTime dueAt = reminder.dueAt.toLocal();

    final tz.TZDateTime scheduledTime = tz.TZDateTime.from(dueAt, tz.local);

    // Uses the user's chosen reminder sound. A reminder scheduled earlier
    // keeps the sound that was selected when it was scheduled.
    final ReminderSound sound = await reminderSoundStore.read();
    await ensureReminderChannel(
      _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >(),
      sound,
    );

    final NotificationDetails details = NotificationDetails(
      android: reminderAndroidDetails(
        sound,
        notificationCategory: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
      ),
    );

    await _notifications.zonedSchedule(
      id: reminder.occurrenceId.hashCode,
      title: reminder.title,
      body: reminder.instructions ?? 'Alera reminder',
      scheduledDate: scheduledTime,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: reminder.occurrenceId,
    );
  }

  Future<void> cancelReminder(ElderlyReminder reminder) async {
    await _notifications.cancel(id: reminder.occurrenceId.hashCode);
  }
}
