import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../config/app_config.dart';
import '../auth/caregiver_session_controller.dart';
import 'dto/caregiver_insight_dto.dart';

abstract interface class CaregiverInsightDataSource {
  Future<CaregiverInsightResponseDto> fetchInsights(String patientId);
}

class CaregiverInsightApiDataSource implements CaregiverInsightDataSource {
  final http.Client _client;
  final CaregiverSession _session;
  final Duration timeout;

  CaregiverInsightApiDataSource({
    http.Client? client,
    CaregiverSession? session,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _session = session ?? CaregiverSessionController.instance;

  @override
  Future<CaregiverInsightResponseDto> fetchInsights(String patientId) async {
    final token = _session.accessToken;
    if (token == null || token.isEmpty) {
      throw const CaregiverInsightApiFailure('Please sign in again.');
    }

    final uri = Uri.parse(
      '${AppConfig.backendBaseUrl}/api/v1/patients/'
      '${Uri.encodeComponent(patientId)}/caregiver-insights',
    );

    try {
      final response = await _client
          .get(uri, headers: {'authorization': 'Bearer $token'})
          .timeout(timeout);

      if (response.statusCode == 401) {
        await _session.clearInvalidSession();
        throw const CaregiverInsightApiFailure(
          'Please sign in again.',
          statusCode: 401,
        );
      }
      if (response.statusCode == 403) {
        throw const CaregiverInsightApiFailure(
          'You do not have permission to view this patient.',
          statusCode: 403,
        );
      }
      if (response.statusCode == 404) {
        throw const CaregiverInsightApiFailure(
          'Patient not found.',
          statusCode: 404,
        );
      }
      if (response.statusCode >= 500) {
        throw CaregiverInsightApiFailure(
          'The server is temporarily unavailable.',
          statusCode: response.statusCode,
        );
      }
      if (response.statusCode != 200) {
        throw CaregiverInsightApiFailure(
          'Unable to load caregiver insights.',
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException();
      }
      return CaregiverInsightResponseDto.fromJson(decoded);
    } on TimeoutException {
      throw const CaregiverInsightApiFailure(
        'The request timed out. Please try again.',
      );
    } on http.ClientException {
      throw const CaregiverInsightApiFailure(
        'Unable to connect to the server.',
      );
    } on CaregiverInsightApiFailure {
      rethrow;
    } on FormatException {
      throw const CaregiverInsightApiFailure(
        'The server returned an unexpected response.',
      );
    } on TypeError {
      throw const CaregiverInsightApiFailure(
        'The server returned an unexpected response.',
      );
    }
  }
}

class CaregiverInsightApiFailure implements Exception {
  final String message;
  final int? statusCode;

  const CaregiverInsightApiFailure(this.message, {this.statusCode});

  @override
  String toString() => message;
}
