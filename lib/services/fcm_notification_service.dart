import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'alert_notification.dart';
import 'patient_nudge_notification.dart';
import 'reminder_due_notification.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:alera_toast/alera_toast.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../features/caregiver/data/auth/caregiver_session_controller.dart';
import '../features/caregiver/data/auth/caregiver_token_store.dart';

const String _completeReminderAction = 'complete_reminder';
const String _snoozeReminderAction = 'snooze_reminder';

const AndroidNotificationDetails _reminderNotificationDetails =
    AndroidNotificationDetails(
      'alera_patient_reminders_v2',
      'Patient reminders',
      channelDescription: 'Time-sensitive reminders for patients',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      playSound: true,
      enableVibration: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          _completeReminderAction,
          'Complete',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          _snoozeReminderAction,
          'Snooze',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

String _reminderTitle(Map<String, dynamic> data) =>
    data['title'] as String? ?? 'Alera reminder';

String _reminderBody(Map<String, dynamic> data) =>
    data['body'] as String? ??
    data['instructions'] as String? ??
    "It's time for this reminder.";

Future<void> _showActionableReminder(
  FlutterLocalNotificationsPlugin local, {
  required int id,
  required Map<String, dynamic> data,
}) {
  return local.show(
    id: id,
    title: _reminderTitle(data),
    body: _reminderBody(data),
    notificationDetails: const NotificationDetails(
      android: _reminderNotificationDetails,
    ),
    payload: jsonEncode(data),
  );
}

Future<void> _showReminderNotification(
  FlutterLocalNotificationsPlugin local,
  RemoteMessage message,
) async {
  final data = {...message.data, '_notification_event_id': message.messageId};
  await _showActionableReminder(
    local,
    id: message.data['occurrence_id']?.hashCode ?? message.hashCode,
    data: data,
  );
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.data['type'] != 'REMINDER_DUE') return;
  final local = FlutterLocalNotificationsPlugin();
  await local.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  await _showReminderNotification(local, message);
}

@pragma('vm:entry-point')
Future<void> notificationActionBackgroundHandler(
  NotificationResponse response,
) async {
  DartPluginRegistrant.ensureInitialized();
  if (response.actionId != _completeReminderAction &&
      response.actionId != _snoozeReminderAction) {
    return;
  }
  final reminder = ReminderDueNotification.fromLocalPayload(response.payload);
  if (reminder == null) return;
  final isSnooze = response.actionId == _snoozeReminderAction;

  try {
    final session = await SecureCaregiverTokenStore().readSession();
    if (session == null || session.type != SessionType.elderlyPatient) return;
    final result = await http
        .post(
          Uri.parse(
            '${AppConfig.backendBaseUrl}/api/v1/reminders/'
            '${Uri.encodeComponent(reminder.occurrenceId)}/'
            '${isSnooze ? 'snooze' : 'complete'}',
          ),
          headers: {
            'authorization': 'Bearer ${session.token}',
            'content-type': 'application/json',
          },
          body: jsonEncode({
            'client_action_id': _uuidV4(),
            if (isSnooze) 'snooze_minutes': 10,
          }),
        )
        .timeout(const Duration(seconds: 15));
    if ((result.statusCode >= 200 && result.statusCode < 300) ||
        result.statusCode == 409) {
      await AleraToast.show(
        isSnooze
            ? 'Reminder has been snoozed for 10 minutes'
            : 'Reminder completed',
      );
    }
  } catch (error) {
    if (kDebugMode) debugPrint('Reminder notification action failed: $error');
  }
}

String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

class FcmNotificationService {
  FcmNotificationService._();
  static final instance = FcmNotificationService._();
  final _local = FlutterLocalNotificationsPlugin();
  // Resolve Firebase only inside the operation using it. In particular,
  // register's best-effort guard must also cover an unavailable Firebase app.
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  String? _token;
  bool _debugTokenPrinted = false;
  StreamSubscription<String>? _tokenRefreshSubscription;
  String? get debugToken => kDebugMode ? _token : null;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _handleLocalResponse,
      onDidReceiveBackgroundNotificationResponse:
          notificationActionBackgroundHandler,
    );

    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'alera_alerts',
            'Alera alerts',
            description: 'Caregiver health alerts',
            importance: Importance.high,
          ),
        );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'alera_patient_reminders_v2',
            'Patient reminders',
            description: 'Time-sensitive reminders for patients',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'alera_nudges',
            'Alera reminders',
            description: 'Caregiver reminders for patients',
            importance: Importance.high,
          ),
        );
    FirebaseMessaging.onMessage.listen(_foreground);
    FirebaseMessaging.onMessageOpenedApp.listen(_handle);
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handle(initialMessage);
    final localLaunch = await _local.getNotificationAppLaunchDetails();
    if (localLaunch?.didNotificationLaunchApp ?? false) {
      final response = localLaunch?.notificationResponse;
      if (response != null) _handleLocalResponse(response);
    }
  }

  Future<void> register(CaregiverSessionController session) async {
    if (session.sessionType == null) return;
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    try {
      await _messaging.requestPermission();
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      _token = token;
      await _send(token, session.accessToken, session.sessionType);
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((t) async {
        _token = t;
        await _send(t, session.accessToken, session.sessionType);
      });
    } catch (error) {
      if (kDebugMode) debugPrint('FCM registration failed: $error');
    }
  }

  Future<void> unregister(CaregiverSessionController session) async {
    final token = _token;
    final bearer = session.accessToken;
    final sessionType = session.sessionType;

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _token = null;
    _debugTokenPrinted = false;

    if (token == null || bearer == null) return;
    try {
      await http.delete(
        Uri.parse('${AppConfig.backendBaseUrl}${_tokenPath(sessionType)}'),
        headers: {
          'authorization': 'Bearer $bearer',
          'content-type': 'application/json',
        },
        body: jsonEncode({'token': token}),
      );
    } catch (error) {
      if (kDebugMode) debugPrint('FCM unregister failed: $error');
    }
  }

  Future<void> _send(
    String token,
    String? bearer,
    SessionType? sessionType,
  ) async {
    if (bearer == null) return;
    try {
      final response = await http.post(
        Uri.parse(
          '${AppConfig.backendBaseUrl}'
          '${_tokenPath(sessionType)}',
        ),
        headers: {
          'authorization': 'Bearer $bearer',
          'content-type': 'application/json',
        },
        body: jsonEncode({'token': token, 'platform': 'ANDROID'}),
      );
      assert(() {
        if (!_debugTokenPrinted &&
            response.statusCode >= 200 &&
            response.statusCode < 300) {
          debugPrint(
            'FCM token: ${FcmNotificationService.instance.debugToken}',
          );
          _debugTokenPrinted = true;
        }
        return true;
      }());
    } catch (error) {
      if (kDebugMode) debugPrint('FCM token upload failed: $error');
    }
  }

  Future<void> _foreground(RemoteMessage m) async {
    if (m.data['type'] == 'REMINDER_DUE') {
      await _showReminderNotification(_local, m);
      return;
    }

    AlertNotificationArrivalBus.instance.handle(
      AlertNotification.parse(m.data, messageId: m.messageId),
    );

    final d = {...m.data, '_notification_event_id': m.messageId};
    final isReminder =
        m.data['type'] == 'NUDGE' || m.data['type'] == 'REMINDER_DUE';
    await _local.show(
      id: m.hashCode,
      title:
          m.notification?.title ??
          (isReminder ? 'Alera reminder' : 'Alera health alert'),
      body:
          m.notification?.body ??
          (isReminder
              ? 'You have a reminder due.'
              : 'A new alert needs your attention.'),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          isReminder ? 'alera_nudges' : 'alera_alerts',
          isReminder ? 'Alera reminders' : 'Alera alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(d),
    );
  }

  void _handle(RemoteMessage message) {
    NotificationTapBus.instance.handle(
      AlertNotification.parse(message.data, messageId: message.messageId),
    );
    PatientNudgeTapBus.instance.handle(
      PatientNudgeNotification.parse(
        message.data,
        messageId: message.messageId,
      ),
    );
    ReminderDueTapBus.instance.handle(
      ReminderDueNotification.parse(message.data, messageId: message.messageId),
    );
  }

  void _handleLocalResponse(NotificationResponse response) {
    final parsed = ReminderDueNotification.fromLocalPayload(response.payload);
    final action = switch (response.actionId) {
      _completeReminderAction => ReminderNotificationAction.complete,
      _snoozeReminderAction => ReminderNotificationAction.snooze,
      _ => ReminderNotificationAction.open,
    };
    ReminderDueTapBus.instance.handle(parsed?.withAction(action));
    if (action == ReminderNotificationAction.open) {
      NotificationTapBus.instance.handle(
        AlertNotification.fromLocalPayload(response.payload),
      );
      PatientNudgeTapBus.instance.handle(
        PatientNudgeNotification.fromLocalPayload(response.payload),
      );
    }
  }

  String _tokenPath(SessionType? sessionType) =>
      sessionType == SessionType.elderlyPatient
      ? '/api/v1/devices/fcm-token'
      : '/api/v1/devices/fcm-token';
}
