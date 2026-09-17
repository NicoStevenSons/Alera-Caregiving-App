import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../../../config/app_config.dart';
import '../../domain/models/caregiver_nudge.dart';
import '../auth/caregiver_session_controller.dart';

abstract interface class CaregiverNudgeDataSource {
  Future<void> sendNudge(String patientId, CaregiverNudgeType type);
}

class CaregiverNudgeApiDataSource implements CaregiverNudgeDataSource {
  final http.Client _client;
  final CaregiverSession _session;
  final Duration timeout;
  final Random _random;

  CaregiverNudgeApiDataSource({
    http.Client? client,
    CaregiverSession? session,
    this.timeout = const Duration(seconds: 15),
    Random? random,
  }) : _client = client ?? http.Client(),
       _session = session ?? CaregiverSessionController.instance,
       _random = random ?? Random.secure();

  @override
  Future<void> sendNudge(String patientId, CaregiverNudgeType type) async {
    final token = _session.accessToken;
    if (token == null || token.isEmpty) {
      throw const CaregiverNudgeFailure('Please sign in again.', statusCode: 401);
    }
    try {
      final response = await _client
          .post(
            Uri.parse(
              '${AppConfig.backendBaseUrl}/api/v1/patients/'
              '${Uri.encodeComponent(patientId)}/nudges',
            ),
            headers: {
              'authorization': 'Bearer $token',
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'nudge_type': type.apiValue,
              'client_action_id': _uuidV4(),
            }),
          )
          .timeout(timeout);
      if (_session.accessToken != token) {
        throw const CaregiverNudgeFailure('Please sign in again.', statusCode: 401);
      }
      if (response.statusCode == 401) {
        await _session.clearInvalidSession();
        throw const CaregiverNudgeFailure('Please sign in again.', statusCode: 401);
      }
      if (response.statusCode == 403) {
        throw const CaregiverNudgeFailure(
          'Only assigned caregivers can send this reminder.',
          statusCode: 403,
        );
      }
      if (response.statusCode == 404) {
        throw const CaregiverNudgeFailure(
          'This patient is no longer assigned to you.',
          statusCode: 404,
        );
      }
      if (response.statusCode != 201) {
        throw CaregiverNudgeFailure(
          response.statusCode >= 500
              ? 'The server is temporarily unavailable.'
              : 'Unable to send the reminder. Please try again.',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw const CaregiverNudgeFailure(
        'The request timed out. Please try again.',
      );
    } on http.ClientException {
      throw const CaregiverNudgeFailure(
        'Unable to connect. Please try again.',
      );
    } on CaregiverNudgeFailure {
      rethrow;
    } catch (_) {
      throw const CaregiverNudgeFailure(
        'Unable to send the reminder. Please try again.',
      );
    }
  }

  String _uuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

class CaregiverNudgeFailure implements Exception {
  final String message;
  final int? statusCode;

  const CaregiverNudgeFailure(this.message, {this.statusCode});
}
