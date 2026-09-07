import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../config/app_config.dart';
import '../auth/caregiver_session_controller.dart';
import 'dto/patient_dto.dart';

abstract interface class CaregiverPatientDataSource {
  Future<PatientCreatedResponse> createPatient(CreatePatientRequest request);
  Future<PatientAccessCodeResponse> createAccessCode(String patientId);
}

abstract interface class CaregiverPatientReadDataSource {
  Future<PaginatedPatientListDto> fetchPatients({
    int limit = 100,
    int offset = 0,
  });
  Future<PatientDetailDto> fetchPatient(String patientId);
}

class CaregiverPatientApiDataSource
    implements CaregiverPatientDataSource, CaregiverPatientReadDataSource {
  final http.Client _client;
  final CaregiverSession _session;
  final Duration timeout;

  CaregiverPatientApiDataSource({
    http.Client? client,
    CaregiverSession? session,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _session = session ?? CaregiverSessionController.instance;

  @override
  Future<PaginatedPatientListDto> fetchPatients({
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _get('/api/v1/patients?limit=$limit&offset=$offset');
    return _parse(
      () => PaginatedPatientListDto.fromJson(_jsonObject(response)),
    );
  }

  @override
  Future<PatientDetailDto> fetchPatient(String patientId) async {
    final response = await _get(
      '/api/v1/patients/${Uri.encodeComponent(patientId)}',
    );
    return _parse(() => PatientDetailDto.fromJson(_jsonObject(response)));
  }

  @override
  Future<PatientCreatedResponse> createPatient(
    CreatePatientRequest request,
  ) async {
    final response = await _post('/api/v1/patients', request.toJson());
    return PatientCreatedResponse.fromJson(_jsonObject(response));
  }

  @override
  Future<PatientAccessCodeResponse> createAccessCode(String patientId) async {
    final response = await _post(
      '/api/v1/patients/${Uri.encodeComponent(patientId)}/access-codes',
      const {'expires_in_hours': 24},
    );
    return PatientAccessCodeResponse.fromJson(_jsonObject(response));
  }

  Future<http.Response> _post(String path, Map<String, Object?> body) async {
    final token = _session.accessToken;
    if (token == null || token.isEmpty) {
      throw const CaregiverPatientApiFailure('Please sign in again.');
    }
    try {
      final response = await _client
          .post(
            Uri.parse('${AppConfig.backendBaseUrl}$path'),
            headers: {
              'authorization': 'Bearer $token',
              'content-type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
      await _throwForAuth(response);
      if (response.statusCode != 201) {
        throw CaregiverPatientApiFailure(_safeMessage(response));
      }
      return response;
    } on TimeoutException {
      throw const CaregiverPatientApiFailure(
        'The request timed out. Please try again.',
        kind: CaregiverPatientFailureKind.connectivity,
      );
    } on http.ClientException {
      throw const CaregiverPatientApiFailure(
        'Unable to connect. Please try again.',
        kind: CaregiverPatientFailureKind.connectivity,
      );
    } on CaregiverPatientApiFailure {
      rethrow;
    } catch (_) {
      throw const CaregiverPatientApiFailure(
        'The server returned an unexpected response. Please try again.',
      );
    }
  }

  Future<http.Response> _get(String path) async {
    final token = _session.accessToken;
    if (token == null || token.isEmpty) {
      throw const CaregiverPatientApiFailure('Please sign in again.');
    }
    try {
      final response = await _client
          .get(
            Uri.parse('${AppConfig.backendBaseUrl}$path'),
            headers: {'authorization': 'Bearer $token'},
          )
          .timeout(timeout);
      await _throwForAuth(response);
      if (response.statusCode == 404) {
        throw const CaregiverPatientApiFailure(
          'Patient not found.',
          kind: CaregiverPatientFailureKind.notFound,
          statusCode: 404,
        );
      }
      if (response.statusCode >= 500) {
        throw CaregiverPatientApiFailure(
          'The server is temporarily unavailable.',
          kind: CaregiverPatientFailureKind.server,
          statusCode: response.statusCode,
        );
      }
      if (response.statusCode != 200) {
        throw CaregiverPatientApiFailure(
          _safeMessage(response),
          statusCode: response.statusCode,
        );
      }
      return response;
    } on TimeoutException {
      throw const CaregiverPatientApiFailure(
        'The request timed out. Please try again.',
        kind: CaregiverPatientFailureKind.connectivity,
      );
    } on http.ClientException {
      throw const CaregiverPatientApiFailure(
        'Unable to connect. Please try again.',
        kind: CaregiverPatientFailureKind.connectivity,
      );
    } on CaregiverPatientApiFailure {
      rethrow;
    }
  }

  Future<void> _throwForAuth(http.Response response) async {
    if (response.statusCode == 401) {
      await _session.clearInvalidSession();
      throw const CaregiverPatientApiFailure(
        'Please sign in again.',
        kind: CaregiverPatientFailureKind.unauthorized,
        statusCode: 401,
      );
    }
    if (response.statusCode == 403) {
      throw const CaregiverPatientApiFailure(
        'You do not have permission to view patients.',
        kind: CaregiverPatientFailureKind.forbidden,
        statusCode: 403,
      );
    }
  }

  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on FormatException {
      throw const CaregiverPatientApiFailure(
        'The server returned an unexpected response.',
        kind: CaregiverPatientFailureKind.malformed,
      );
    } on TypeError {
      throw const CaregiverPatientApiFailure(
        'The server returned an unexpected response.',
        kind: CaregiverPatientFailureKind.malformed,
      );
    }
  }

  Map<String, dynamic> _jsonObject(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) throw const FormatException();
    return decoded;
  }

  String _safeMessage(http.Response response) {
    if (response.statusCode == 422) {
      try {
        final decoded = jsonDecode(response.body);
        final detail = decoded is Map<String, dynamic>
            ? decoded['detail']
            : null;
        if (detail is List) {
          final messages = detail
              .whereType<Map<String, dynamic>>()
              .map((item) => item['msg'])
              .whereType<String>()
              .toSet()
              .take(3)
              .join(' ');
          if (messages.isNotEmpty) return messages;
        }
      } catch (_) {}
      return 'Please check the patient details and try again.';
    }
    if (response.statusCode == 403) {
      return 'You do not have permission to perform this action.';
    }
    return 'Unable to complete the request. Please try again.';
  }
}

enum CaregiverPatientFailureKind {
  other,
  connectivity,
  server,
  unauthorized,
  forbidden,
  notFound,
  malformed,
}

class CaregiverPatientApiFailure implements Exception {
  final String message;
  final CaregiverPatientFailureKind kind;
  final int? statusCode;
  const CaregiverPatientApiFailure(
    this.message, {
    this.kind = CaregiverPatientFailureKind.other,
    this.statusCode,
  });
}
