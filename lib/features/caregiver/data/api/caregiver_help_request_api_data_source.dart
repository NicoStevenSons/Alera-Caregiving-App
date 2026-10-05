import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../config/app_config.dart';
import '../../../help_requests/domain/help_request.dart';
import '../auth/caregiver_session_controller.dart';

class CaregiverHelpRequestFailure implements Exception {
  const CaregiverHelpRequestFailure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class HelpRequestPage {
  const HelpRequestPage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<HelpRequestRecord> items;
  final int total;
  final int limit;
  final int offset;
}

abstract interface class CaregiverHelpRequestDataSource {
  Future<HelpRequestPage> fetchRequests({
    List<HelpRequestStatus> statuses,
    String? patientId,
    int limit,
    int offset,
  });

  Future<HelpRequestRecord> fetchRequest(String helpRequestId);

  Future<HelpRequestRecord> acknowledge(String helpRequestId);

  Future<HelpRequestRecord> resolve(String helpRequestId);
}

class CaregiverHelpRequestApiDataSource
    implements CaregiverHelpRequestDataSource {
  CaregiverHelpRequestApiDataSource({
    http.Client? client,
    CaregiverSession? session,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _session = session ?? CaregiverSessionController.instance;

  final http.Client _client;
  final CaregiverSession _session;
  final Duration timeout;

  @override
  Future<HelpRequestPage> fetchRequests({
    List<HelpRequestStatus> statuses = const [
      HelpRequestStatus.pending,
      HelpRequestStatus.acknowledged,
    ],
    String? patientId,
    int limit = 100,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{
      'limit': '$limit',
      'offset': '$offset',
      if (statuses.isNotEmpty)
        'status': statuses
            .map((status) => status.apiValue)
            .toList(growable: false),
      'patient_id': ?patientId,
    };

    final decoded = await _request(
      'GET',
      '/api/v1/help-requests',
      query: query,
    );

    if (decoded is! Map<String, dynamic>) {
      throw const CaregiverHelpRequestFailure(
        'The help-request response was invalid.',
      );
    }

    final items = decoded['items'];
    final total = decoded['total'];
    final responseLimit = decoded['limit'];
    final responseOffset = decoded['offset'];

    if (items is! List ||
        total is! int ||
        responseLimit is! int ||
        responseOffset is! int ||
        total < 0 ||
        responseLimit < 1 ||
        responseOffset < 0) {
      throw const CaregiverHelpRequestFailure(
        'The help-request response was invalid.',
      );
    }

    try {
      return HelpRequestPage(
        items: items
            .map((item) {
              if (item is! Map<String, dynamic>) {
                throw const FormatException();
              }

              return HelpRequestRecord.fromJson(item);
            })
            .toList(growable: false),
        total: total,
        limit: responseLimit,
        offset: responseOffset,
      );
    } on FormatException {
      throw const CaregiverHelpRequestFailure(
        'The help-request response was invalid.',
      );
    }
  }

  @override
  Future<HelpRequestRecord> fetchRequest(String helpRequestId) async {
    final decoded = await _request(
      'GET',
      '/api/v1/help-requests/'
          '${Uri.encodeComponent(helpRequestId)}',
    );

    return _record(decoded, expectedId: helpRequestId);
  }

  @override
  Future<HelpRequestRecord> acknowledge(String helpRequestId) {
    return _action(helpRequestId, 'acknowledge');
  }

  @override
  Future<HelpRequestRecord> resolve(String helpRequestId) {
    return _action(helpRequestId, 'resolve');
  }

  Future<HelpRequestRecord> _action(String helpRequestId, String action) async {
    final decoded = await _request(
      'POST',
      '/api/v1/help-requests/'
          '${Uri.encodeComponent(helpRequestId)}/$action',
    );

    return _record(decoded, expectedId: helpRequestId);
  }

  HelpRequestRecord _record(Object? decoded, {required String expectedId}) {
    if (decoded is! Map<String, dynamic>) {
      throw const CaregiverHelpRequestFailure(
        'The help-request response was invalid.',
      );
    }

    try {
      final record = HelpRequestRecord.fromJson(decoded);

      if (record.id.toLowerCase() != expectedId.toLowerCase()) {
        throw const FormatException();
      }

      return record;
    } on FormatException {
      throw const CaregiverHelpRequestFailure(
        'The help-request response was invalid.',
      );
    }
  }

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final token = _session.accessToken;

    if (token == null || token.isEmpty) {
      throw const CaregiverHelpRequestFailure(
        'Please sign in again.',
        statusCode: 401,
      );
    }

    final uri = Uri.parse(
      '${AppConfig.backendBaseUrl}$path',
    ).replace(queryParameters: query);

    try {
      final headers = <String, String>{'authorization': 'Bearer $token'};

      final http.Response response;

      if (method == 'GET') {
        response = await _client.get(uri, headers: headers).timeout(timeout);
      } else if (method == 'POST') {
        response = await _client.post(uri, headers: headers).timeout(timeout);
      } else {
        throw StateError('Unsupported caregiver help-request method.');
      }

      if (_session.accessToken != token) {
        throw const CaregiverHelpRequestFailure(
          'Please sign in again.',
          statusCode: 401,
        );
      }

      if (response.statusCode == 401) {
        if (_session.accessToken == token) {
          await _session.clearInvalidSession();
        }

        throw const CaregiverHelpRequestFailure(
          'Please sign in again.',
          statusCode: 401,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CaregiverHelpRequestFailure(
          _message(response.statusCode),
          statusCode: response.statusCode,
        );
      }

      try {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        throw const CaregiverHelpRequestFailure(
          'The help-request response was invalid.',
        );
      }
    } on TimeoutException {
      throw const CaregiverHelpRequestFailure(
        'The help-request request timed out.',
      );
    } on http.ClientException {
      throw const CaregiverHelpRequestFailure(
        'Unable to reach Alera. Please try again.',
      );
    }
  }

  String _message(int status) => switch (status) {
    403 => 'You cannot access this help request.',
    404 => 'This help request is no longer available.',
    409 => 'This help request has already changed.',
    422 => 'The help-request details were invalid.',
    _ => 'Unable to update help requests. Please try again.',
  };
}
