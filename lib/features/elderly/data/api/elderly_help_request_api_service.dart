import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../../../config/app_config.dart';
import '../../../caregiver/data/auth/caregiver_session_controller.dart';
import '../../../help_requests/domain/help_request.dart';

class ElderlyHelpRequestApiFailure implements Exception {
  const ElderlyHelpRequestApiFailure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

abstract interface class ElderlyHelpRequestDataSource {
  String createActionId();

  Future<HelpRequestRecord?> fetchActive();

  Future<HelpRequestRecord> create({
    required String clientActionId,
    String? message,
  });
}

class ElderlyHelpRequestApiService implements ElderlyHelpRequestDataSource {
  ElderlyHelpRequestApiService({
    http.Client? client,
    CaregiverSession? session,
    Random? random,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _session = session ?? CaregiverSessionController.instance,
       _random = random ?? Random.secure();

  final http.Client _client;
  final CaregiverSession _session;
  final Random _random;
  final Duration timeout;

  @override
  String createActionId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  @override
  Future<HelpRequestRecord?> fetchActive() async {
    final decoded = await _request('GET', '/api/v1/help-requests/active');

    if (decoded == null) return null;

    return _parse(decoded);
  }

  @override
  Future<HelpRequestRecord> create({
    required String clientActionId,
    String? message,
  }) async {
    final trimmedMessage = message?.trim();

    final decoded = await _request(
      'POST',
      '/api/v1/help-requests',
      body: {
        'client_action_id': clientActionId,
        if (trimmedMessage != null && trimmedMessage.isNotEmpty)
          'message': trimmedMessage,
      },
    );

    return _parse(decoded);
  }

  HelpRequestRecord _parse(Object? decoded) {
    if (decoded is! Map<String, dynamic>) {
      throw const ElderlyHelpRequestApiFailure(
        'The help request response was invalid.',
      );
    }

    try {
      return HelpRequestRecord.fromJson(decoded);
    } on FormatException {
      throw const ElderlyHelpRequestApiFailure(
        'The help request response was invalid.',
      );
    }
  }

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final token = _session.accessToken;

    if (token == null || token.isEmpty) {
      throw const ElderlyHelpRequestApiFailure(
        'Please sign in again.',
        statusCode: 401,
      );
    }

    final uri = Uri.parse('${AppConfig.backendBaseUrl}$path');

    try {
      final headers = <String, String>{'authorization': 'Bearer $token'};

      if (body != null) {
        headers['content-type'] = 'application/json';
      }

      final http.Response response;

      if (method == 'GET') {
        response = await _client.get(uri, headers: headers).timeout(timeout);
      } else if (method == 'POST') {
        response = await _client
            .post(uri, headers: headers, body: jsonEncode(body))
            .timeout(timeout);
      } else {
        throw StateError('Unsupported help request method.');
      }

      if (_session.accessToken != token) {
        throw const ElderlyHelpRequestApiFailure(
          'Please sign in again.',
          statusCode: 401,
        );
      }

      if (response.statusCode == 401) {
        await _session.clearInvalidSession();

        throw const ElderlyHelpRequestApiFailure(
          'Please sign in again.',
          statusCode: 401,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ElderlyHelpRequestApiFailure(
          _message(response.statusCode),
          statusCode: response.statusCode,
        );
      }

      try {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        throw const ElderlyHelpRequestApiFailure(
          'The help request response was invalid.',
        );
      }
    } on TimeoutException {
      throw const ElderlyHelpRequestApiFailure(
        'The help request timed out. Please try again.',
      );
    } on http.ClientException {
      throw const ElderlyHelpRequestApiFailure(
        'Unable to reach Alera. Please try again.',
      );
    }
  }

  String _message(int status) => switch (status) {
    403 => 'This account cannot send a help request.',
    409 => 'You already have an active help request.',
    422 => 'Check the help request details and try again.',
    _ => 'Unable to request help. Please try again.',
  };
}
