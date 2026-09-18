import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../config/app_config.dart';
import '../auth/caregiver_session_controller.dart';
import 'dto/vital_trend_dto.dart';

abstract interface class CaregiverVitalTrendDataSource {
  Future<VitalTrendDto> fetchTrend({
    required String patientId,
    required VitalTrendMetric metric,
    required VitalTrendRange range,
  });
}

class CaregiverVitalTrendApiDataSource
    implements CaregiverVitalTrendDataSource {
  final http.Client _client;
  final CaregiverSession _session;
  final Duration timeout;

  CaregiverVitalTrendApiDataSource({
    http.Client? client,
    CaregiverSession? session,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _session = session ?? CaregiverSessionController.instance;

  @override
  Future<VitalTrendDto> fetchTrend({
    required String patientId,
    required VitalTrendMetric metric,
    required VitalTrendRange range,
  }) async {
    final token = _session.accessToken;

    if (token == null || token.isEmpty) {
      throw const CaregiverVitalTrendApiFailure('Please sign in again.');
    }

    final uri =
        Uri.parse(
          '${AppConfig.backendBaseUrl}'
          '/api/v1/patients/${Uri.encodeComponent(patientId)}'
          '/vital-trends',
        ).replace(
          queryParameters: {
            'metric_type': metric.apiValue,
            'range': range.apiValue,
          },
        );

    try {
      final response = await _client
          .get(uri, headers: {'authorization': 'Bearer $token'})
          .timeout(timeout);

      if (response.statusCode == 401) {
        await _session.clearInvalidSession();

        throw const CaregiverVitalTrendApiFailure(
          'Please sign in again.',
          statusCode: 401,
        );
      }

      if (response.statusCode == 403) {
        throw const CaregiverVitalTrendApiFailure(
          'You do not have permission to view this patient.',
          statusCode: 403,
        );
      }

      if (response.statusCode == 404) {
        throw const CaregiverVitalTrendApiFailure(
          'Patient not found.',
          statusCode: 404,
        );
      }

      if (response.statusCode >= 500) {
        throw CaregiverVitalTrendApiFailure(
          'The server is temporarily unavailable.',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode != 200) {
        throw CaregiverVitalTrendApiFailure(
          'Unable to load vital trends.',
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException();
      }

      return VitalTrendDto.fromJson(decoded);
    } on TimeoutException {
      throw const CaregiverVitalTrendApiFailure(
        'The request timed out. Please try again.',
      );
    } on http.ClientException {
      throw const CaregiverVitalTrendApiFailure(
        'Unable to connect to the server.',
      );
    } on CaregiverVitalTrendApiFailure {
      rethrow;
    } on FormatException {
      throw const CaregiverVitalTrendApiFailure(
        'The server returned an unexpected response.',
      );
    } on TypeError {
      throw const CaregiverVitalTrendApiFailure(
        'The server returned an unexpected response.',
      );
    }
  }
}

class CaregiverVitalTrendApiFailure implements Exception {
  final String message;
  final int? statusCode;

  const CaregiverVitalTrendApiFailure(this.message, {this.statusCode});

  @override
  String toString() => message;
}
