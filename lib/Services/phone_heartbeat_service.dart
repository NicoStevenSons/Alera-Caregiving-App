import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';

import '../features/elderly/data/api/device_status_api_service.dart';

class PhoneHeartbeatService {
  final DeviceStatusApiService deviceStatusApiService;
  final Battery _battery;

  Timer? _timer;
  bool _sending = false;

  PhoneHeartbeatService({
    required this.deviceStatusApiService,
    Battery? battery,
  }) : _battery = battery ?? Battery();

  void start() {
    if (_timer != null) {
      return;
    }

    //send immediately when monitoring startsss
    unawaited(_sendHeartbeat());

    _timer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => unawaited(_sendHeartbeat()),
    );

    debugPrint('Phone heartbeat started.');
  }

  void stop() {
    _timer?.cancel();
    _timer = null;

    debugPrint('Phone heartbeat stopped.');
  }

  Future<void> _sendHeartbeat() async {
    if (_sending) {
      return;
    }

    _sending = true;

    try {
      final batteryPercent = await _battery.batteryLevel;

      debugPrint('Sending phone heartbeat: battery=$batteryPercent%');

      await deviceStatusApiService.sendPhoneStatus(
        connectionStatus: 'CONNECTED',
        batteryPercent: batteryPercent,
      );
    } catch (error) {
      debugPrint('Phone heartbeat failed: $error');
    } finally {
      _sending = false;
    }
  }
}
