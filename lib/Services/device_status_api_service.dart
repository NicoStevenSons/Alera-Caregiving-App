import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../features/caregiver/data/auth/caregiver_session_controller.dart';
import '../models/device_status_data.dart';

class DeviceStatusApiService {
  final String baseUrl;
  final String patientId;
  final CaregiverSession _session;
  final http.Client _client;
  final Duration timeout;

  DeviceStatusApiService({
    required this.baseUrl,
    required this.patientId,
    CaregiverSession? session,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _session = session ?? CaregiverSessionController.instance,
       _client = client ?? http.Client();

  Future<void> sendWatchStatus(DeviceStatusData data) async {
    final connectionStatus = switch (data.connectedToPhone) {
      true => 'CONNECTED',
      false => 'DISCONNECTED',
      null => 'UNKNOWN',
    };

    final reportedAt =
        DateTime.tryParse(data.measuredAt ?? '')?.toUtc() ??
        DateTime.now().toUtc();

    await _send({
      'patient_id': patientId,
      'device_type': 'WATCH',
      'device_name': data.deviceName,
      'device_model': data.deviceModel,
      'battery_percent': data.batteryPercent,
      'connection_status': connectionStatus,
      'reported_at': reportedAt.toIso8601String(),
    });
  }

  Future<void> sendPhoneStatus({
    required String connectionStatus,
    int? batteryPercent,
    String? deviceName,
    String? deviceModel,
  }) async {
    await _send({
      'patient_id': patientId,
      'device_type': 'PHONE',
      'device_name': deviceName,
      'device_model': deviceModel,
      'battery_percent': batteryPercent,
      'connection_status': connectionStatus,
      'reported_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> _send(Map<String, Object?> payload) async {
    final token = _session.accessToken;

    if (token == null || token.isEmpty) {
      debugPrint('Device status not sent: no patient session token.');
      return;
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/v1/device-status'),
            headers: {
              'authorization': 'Bearer $token',
              'content-type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(timeout);

      debugPrint(
        'Device status response: '
        '${response.statusCode} ${response.body}',
      );
    } on TimeoutException {
      debugPrint('Device status upload timed out.');
    } on http.ClientException catch (error) {
      debugPrint('Device status network error: $error');
    } catch (error) {
      debugPrint('Device status upload failed: $error');
    }
  }
}