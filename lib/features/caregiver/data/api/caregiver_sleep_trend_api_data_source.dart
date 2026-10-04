import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../config/app_config.dart';
import '../auth/caregiver_session_controller.dart';
import 'dto/sleep_trend_dto.dart';

abstract interface class CaregiverSleepTrendDataSource {
  Future<SleepTrendDto> fetchTrend({
    required String patientId,
    required SleepTrendRange range,
  });
}

class CaregiverSleepTrendApiDataSource
    implements CaregiverSleepTrendDataSource {
  final http.Client _client;
  final CaregiverSession _session;
  final Duration timeout;

  CaregiverSleepTrendApiDataSource({
    http.Client? client,
    CaregiverSession? session,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _session = session ?? CaregiverSessionController.instance;

  @override
  Future<SleepTrendDto> fetchTrend({
    required String patientId,
    required SleepTrendRange range,
  }) async {
    final token = _session.accessToken;

    if (token == null || token.isEmpty) {
      throw const CaregiverSleepTrendApiFailure('Please sign in again.');
    }

    final uri = Uri.parse(
      '${AppConfig.backendBaseUrl}'
      '/api/v1/patients/${Uri.encodeComponent(patientId)}'
      '/sleep-trends',
    ).replace(queryParameters: {'range': range.apiValue});

    try {
      final response = await _client
          .get(uri, headers: {'authorization': 'Bearer $token'})
          .timeout(timeout);

      if (response.statusCode == 401) {
        await _session.clearInvalidSession();

        throw const CaregiverSleepTrendApiFailure(
          'Please sign in again.',
          statusCode: 401,
        );
      }

      if (response.statusCode == 403) {
        throw const CaregiverSleepTrendApiFailure(
          'You do not have permission to view this patient.',
          statusCode: 403,
        );
      }

      if (response.statusCode == 404) {
        throw const CaregiverSleepTrendApiFailure(
          'Patient not found.',
          statusCode: 404,
        );
      }

      if (response.statusCode >= 500) {
        throw CaregiverSleepTrendApiFailure(
          'The server is temporarily unavailable.',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode != 200) {
        throw CaregiverSleepTrendApiFailure(
          'Unable to load sleep trends.',
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException();
      }

      return SleepTrendDto.fromJson(decoded);
    } on TimeoutException {
      throw const CaregiverSleepTrendApiFailure(
        'The request timed out. Please try again.',
      );
    } on http.ClientException {
      throw const CaregiverSleepTrendApiFailure(
        'Unable to connect to the server.',
      );
    } on CaregiverSleepTrendApiFailure {
      rethrow;
    } on FormatException {
      throw const CaregiverSleepTrendApiFailure(
        'The server returned an unexpected response.',
      );
    } on TypeError {
      throw const CaregiverSleepTrendApiFailure(
        'The server returned an unexpected response.',
      );
    }
  }
}

class CaregiverSleepTrendApiFailure implements Exception {
  final String message;
  final int? statusCode;

  const CaregiverSleepTrendApiFailure(this.message, {this.statusCode});

  @override
  String toString() => message;
}
