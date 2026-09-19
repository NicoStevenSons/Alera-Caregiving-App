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

String _alertTitle(Map<String, dynamic> data) =>
    data['title'] as String? ?? 'Alera health alert';

String _alertBody(Map<String, dynamic> data) =>
    data['body'] as String? ?? 'A new alert needs your attention.';

String _alertHeadline(Map<String, dynamic> data) {
  final title = _alertTitle(data).trim();
  return title.contains(':') ? title.replaceFirst(':', ' •') : title;
}

String _alertReading(Map<String, dynamic> data) {
  final body = _alertBody(data);
  final parts = body.split('•');
  return (parts.length > 1 ? parts.last : body).trim();
}

String _alertDetails(Map<String, dynamic> data) {
  final metricType = (data['metric_type'] as String? ?? '').toUpperCase();
  final title = _alertTitle(data).toLowerCase();
  final reading = _alertReading(data);

  switch (metricType) {
    case 'HEART_RATE':
      if (title.contains('high')) {
        return title.contains('critical')
            ? 'Heart rate is dangerously high at $reading.'
            : 'Heart rate is high at $reading.';
      }
      if (title.contains('low')) {
        return title.contains('critical')
            ? 'Heart rate is dangerously low at $reading.'
            : 'Heart rate is low at $reading.';
      }
      return 'Heart rate needs attention at $reading.';
    case 'SPO2':
      if (title.contains('low')) {
        return title.contains('critical')
            ? 'SpO₂ is dangerously low at $reading.'
            : 'SpO₂ is low at $reading.';
      }
      return 'SpO₂ needs attention at $reading.';
    case 'BATTERY_LEVEL':
      return reading.isNotEmpty
          ? 'Watch battery is low at $reading.'
          : 'Watch battery is low.';
    default:
      if (title.contains('disconnected')) {
        return 'Smartwatch disconnected. Please check the device connection.';
      }
      return _alertBody(data);
  }
}

Future<void> _showAlertNotification(
  FlutterLocalNotificationsPlugin local, {
  required int id,
  required Map<String, dynamic> data,
}) async {
  final String title = _alertTitle(data);
  final String headline = _alertHeadline(data);
  final String details = _alertDetails(data);
  final String? patientName = (data['patient_display_name'] as String?)?.trim();
  final String metricType = data['metric_type'] as String? ?? 'SYSTEM';
  final String? patientId = (data['patient_id'] as String?)?.trim();

  MessagingStyleInformation? messagingStyle;

  if (patientName != null && patientName.isNotEmpty) {
    try {
      final bytes = await AleraNotificationAvatar.render(
        patientName: patientName,
        metricType: metricType,
      );

      final alertPerson = Person(
        name: headline,
        key: patientId?.isNotEmpty == true ? patientId : patientName,
        important: true,
        icon: bytes != null && bytes.isNotEmpty
            ? ByteArrayAndroidIcon(bytes)
            : null,
      );

      messagingStyle = MessagingStyleInformation(
        const Person(name: 'Alera', key: 'alera'),
        conversationTitle: patientName,
        groupConversation: false,
        messages: <Message>[Message(details, DateTime.now(), alertPerson)],
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Alert notification avatar rendering failed: $error');
      }
    }
  }

  await local.show(
    id: id,
    title: patientName ?? title,
    body: '$headline — $details',
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        'alera_alerts',
        'Alera alerts',
        channelDescription: 'Caregiver health alerts',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: messagingStyle,
        visibility: NotificationVisibility.private,
        category: AndroidNotificationCategory.message,
      ),
    ),
    payload: jsonEncode(data),
  );
}

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
  final type = message.data['type'];
  if (type != 'REMINDER_DUE' && type != 'ALERT') return;

  final local = FlutterLocalNotificationsPlugin();
  await local.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  if (type == 'REMINDER_DUE') {
    await _showReminderNotification(local, message);
    return;
  }

  final data = {...message.data, '_notification_event_id': message.messageId};
  await _showAlertNotification(
    local,
    id: message.data['alert_id']?.hashCode ?? message.hashCode,
    data: data,
  );
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

    if (m.data['type'] == 'ALERT') {
      AlertNotificationArrivalBus.instance.handle(
        AlertNotification.parse(m.data, messageId: m.messageId),
      );
      final d = {
        ...m.data,
        if (!m.data.containsKey('title') && m.notification?.title != null)
          'title': m.notification!.title!,
        if (!m.data.containsKey('body') && m.notification?.body != null)
          'body': m.notification!.body!,
        '_notification_event_id': m.messageId,
      };
      await _showAlertNotification(_local, id: m.hashCode, data: d);
      return;
    }

    final d = {...m.data, '_notification_event_id': m.messageId};
    await _local.show(
      id: m.hashCode,
      title: m.notification?.title ?? 'Alera reminder',
      body: m.notification?.body ?? 'You have a reminder due.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'alera_nudges',
          'Alera reminders',
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
