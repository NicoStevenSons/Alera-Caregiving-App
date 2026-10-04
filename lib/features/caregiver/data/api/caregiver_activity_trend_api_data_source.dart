import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../config/app_config.dart';
import '../auth/caregiver_session_controller.dart';
import 'dto/activity_trend_dto.dart';

abstract interface class CaregiverActivityTrendDataSource {
  Future<ActivityTrendDto> fetchTrend({
    required String patientId,
    required ActivityTrendRange range,
  });
}

class CaregiverActivityTrendApiDataSource
    implements CaregiverActivityTrendDataSource {
  final http.Client _client;
  final CaregiverSession _session;
  final Duration timeout;

  CaregiverActivityTrendApiDataSource({
    http.Client? client,
    CaregiverSession? session,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _session = session ?? CaregiverSessionController.instance;

  @override
  Future<ActivityTrendDto> fetchTrend({
    required String patientId,
    required ActivityTrendRange range,
  }) async {
    final token = _session.accessToken;

    if (token == null || token.isEmpty) {
      throw const CaregiverActivityTrendApiFailure('Please sign in again.');
    }

    final uri = Uri.parse(
      '${AppConfig.backendBaseUrl}'
      '/api/v1/patients/${Uri.encodeComponent(patientId)}'
      '/activity-trends',
    ).replace(queryParameters: {'range': range.apiValue});

    try {
      final response = await _client
          .get(uri, headers: {'authorization': 'Bearer $token'})
          .timeout(timeout);

      if (response.statusCode == 401) {
        await _session.clearInvalidSession();

        throw const CaregiverActivityTrendApiFailure(
          'Please sign in again.',
          statusCode: 401,
        );
      }

      if (response.statusCode == 403) {
        throw const CaregiverActivityTrendApiFailure(
          'You do not have permission to view this patient.',
          statusCode: 403,
        );
      }

      if (response.statusCode == 404) {
        throw const CaregiverActivityTrendApiFailure(
          'Patient not found.',
          statusCode: 404,
        );
      }

      if (response.statusCode >= 500) {
        throw CaregiverActivityTrendApiFailure(
          'The server is temporarily unavailable.',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode != 200) {
        throw CaregiverActivityTrendApiFailure(
          'Unable to load activity trends.',
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException();
      }

      return ActivityTrendDto.fromJson(decoded);
    } on TimeoutException {
      throw const CaregiverActivityTrendApiFailure(
        'The request timed out. Please try again.',
      );
    } on http.ClientException {
      throw const CaregiverActivityTrendApiFailure(
        'Unable to connect to the server.',
      );
    } on CaregiverActivityTrendApiFailure {
      rethrow;
    } on FormatException {
      throw const CaregiverActivityTrendApiFailure(
        'The server returned an unexpected response.',
      );
    } on TypeError {
      throw const CaregiverActivityTrendApiFailure(
        'The server returned an unexpected response.',
      );
    }
  }
}

class CaregiverActivityTrendApiFailure implements Exception {
  final String message;
  final int? statusCode;

  const CaregiverActivityTrendApiFailure(this.message, {this.statusCode});

  @override
  String toString() => message;
}
