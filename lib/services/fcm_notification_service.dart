import 'dart:convert';
import 'alert_notification.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../features/caregiver/data/auth/caregiver_session_controller.dart';
import '../features/caregiver/data/auth/caregiver_token_store.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
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
  String? get debugToken => kDebugMode ? _token : null;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _local.initialize(
      settings: const InitializationSettings(
      android: AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      ),
    ),
    onDidReceiveNotificationResponse: (r) =>
        NotificationTapBus.instance.handle(
      AlertNotification.fromLocalPayload(
        r.payload,
      ),
    ),
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
    FirebaseMessaging.onMessage.listen(_foreground);
    FirebaseMessaging.onMessageOpenedApp.listen(_handle);
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handle(initialMessage);
    final localLaunch = await _local.getNotificationAppLaunchDetails();
    if (localLaunch?.didNotificationLaunchApp ?? false) {
      NotificationTapBus.instance.handle(
        AlertNotification.fromLocalPayload(
          localLaunch?.notificationResponse?.payload,
        ),
      );
    }
  }

  Future<void> register(CaregiverSessionController session) async {
    if (session.sessionType != SessionType.caregiver) return;
    try {
      await _messaging.requestPermission();
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      _token = token;
      await _send(token, session.accessToken);
      _messaging.onTokenRefresh.listen((t) async {
        _token = t;
        await _send(t, session.accessToken);
      });
    } catch (_) {}
  }

  Future<void> unregister(CaregiverSessionController session) async {
    final token = _token;
    if (token == null) return;
    try {
      await http.delete(
        Uri.parse('${AppConfig.backendBaseUrl}/api/v1/devices/fcm-token'),
        headers: {
          'authorization': 'Bearer ${session.accessToken}',
          'content-type': 'application/json',
        },
        body: jsonEncode({'token': token}),
      );
    } catch (_) {}
    _token = null;
  }

  Future<void> _send(String token, String? bearer) async {
    if (bearer == null) return;
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendBaseUrl}/api/v1/devices/fcm-token'),
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
    } catch (_) {}
  }

  Future<void> _foreground(RemoteMessage m) async {
    final d = {...m.data, '_notification_event_id': m.messageId};
    await _local.show(
  id: m.hashCode,
  title:
      m.notification?.title ??
      'Alera health alert',
  body:
      m.notification?.body ??
      'A new alert needs your attention.',
  notificationDetails:
      const NotificationDetails(
    android: AndroidNotificationDetails(
      'alera_alerts',
      'Alera alerts',
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
  }
}
