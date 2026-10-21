import 'package:flutter/services.dart';

import '../config/app_config.dart';

class MonitoringService {
  MonitoringService._();

  static const MethodChannel _channel = MethodChannel(
    'com.alera.payloadextraction/monitoring',
  );

  static Future<void> start({
    required String accessToken,
    required String patientId,
  }) async {
    await _channel.invokeMethod<bool>(
      'startMonitoring',
      {
        'accessToken': accessToken,
        'patientId': patientId,
        'baseUrl': AppConfig.backendBaseUrl,
      },
    );
  }

  static Future<void> stop() async {
    await _channel.invokeMethod<bool>('stopMonitoring');
  }
}