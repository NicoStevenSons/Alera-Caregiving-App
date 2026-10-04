import 'package:flutter/services.dart';

class MonitoringService {
  MonitoringService._();

  static const MethodChannel _channel = MethodChannel(
    'com.alera.payloadextraction/monitoring',
  );

  static Future<void> start() async {
    await _channel.invokeMethod<bool>('startMonitoring');
  }

  static Future<void> stop() async {
    await _channel.invokeMethod<bool>('stopMonitoring');
  }
}
