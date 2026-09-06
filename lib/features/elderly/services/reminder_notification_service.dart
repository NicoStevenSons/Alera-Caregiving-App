import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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

    const InitializationSettings settings =
        InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: settings,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();

    await androidPlugin?.requestExactAlarmsPermission();
  }

  Future<void> scheduleReminder(
    ElderlyReminder reminder,
  ) async {
    final DateTime dueAt = reminder.dueAt.toLocal();

    final tz.TZDateTime scheduledTime =
        tz.TZDateTime.from(
      dueAt,
      tz.local,
    );

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'alera_reminders',
      'Alera Reminders',
      channelDescription:
          'Reminder alerts for elderly patients',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
    );

    const NotificationDetails details =
        NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
    id: reminder.occurrenceId.hashCode,
    title: reminder.title,
    body: reminder.instructions ?? 'Alera reminder',
    scheduledDate: scheduledTime,
    notificationDetails: details,
    androidScheduleMode:
      AndroidScheduleMode.exactAllowWhileIdle,
   payload: reminder.occurrenceId,
    );
  }

 Future<void> cancelReminder(
  ElderlyReminder reminder,
) async {
  await _notifications.cancel(
    id: reminder.occurrenceId.hashCode,
  );
}

}