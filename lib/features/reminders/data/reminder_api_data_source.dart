import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
import '../../caregiver/data/auth/caregiver_session_controller.dart';
import '../domain/reminder_models.dart';
import 'reminder_dto.dart';

class ReminderApiFailure implements Exception {
  const ReminderApiFailure(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

abstract interface class ReminderDataSource {
  Future<ReminderPage<ReminderOccurrence>> fetchOccurrences({
    String? patientId,
    List<ReminderOccurrenceStatus> statuses = const [],
    int limit = 100,
    int offset = 0,
  });
  Future<ReminderPage<ReminderTemplate>> fetchTemplates(
    String patientId, {
    List<ReminderTemplateStatus> statuses = const [],
    int limit = 100,
    int offset = 0,
  });
  Future<ReminderTemplate> createTemplate(ReminderTemplateDraft draft);
  Future<ReminderTemplate> updateTemplate(
    String templateId,
    Map<String, Object?> changes,
  );
  Future<ReminderTemplate> archiveTemplate(String templateId);
  Future<ReminderActionResult> complete(String occurrenceId, {String? note});
  Future<ReminderActionResult> snooze(
    String occurrenceId, {
    int? snoozeMinutes,
    String? note,
  });
  Future<ReminderActionResult> completeOnBehalf(
    String occurrenceId,
    String note,
  );
  Future<ReminderActionResult> cancel(String occurrenceId, String note);
  Future<ReminderActionResult> snoozeOnBehalf(
    String occurrenceId,
    String note, {
    int? snoozeMinutes,
  });
}

class ReminderApiDataSource implements ReminderDataSource {
  ReminderApiDataSource({
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

  Future<ReminderOccurrence> fetchOccurrence(String occurrenceId) async {
    final decoded = await _request(
      'GET',
      '/api/v1/reminders/${Uri.encodeComponent(occurrenceId)}',
    );
    return ReminderOccurrenceDto.fromJson(_object(decoded)).value;
  }

  @override
  Future<ReminderPage<ReminderOccurrence>> fetchOccurrences({
    String? patientId,
    List<ReminderOccurrenceStatus> statuses = const [],
    int limit = 100,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{'limit': '$limit', 'offset': '$offset'};
    if (patientId != null) query['patient_id'] = patientId;
    if (statuses.isNotEmpty) {
      query['status'] = statuses.map((e) => e.apiValue).toList();
    }
    final decoded = await _request('GET', '/api/v1/reminders', query: query);
    return parseReminderPage(
      decoded,
      (json) => ReminderOccurrenceDto.fromJson(json).value,
    );
  }

  @override
  Future<ReminderPage<ReminderTemplate>> fetchTemplates(
    String patientId, {
    List<ReminderTemplateStatus> statuses = const [],
    int limit = 100,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{
      'patient_id': patientId,
      'limit': '$limit',
      'offset': '$offset',
    };
    if (statuses.isNotEmpty) {
      query['status'] = statuses.map((e) => e.apiValue).toList();
    }
    final decoded = await _request(
      'GET',
      '/api/v1/reminder-templates',
      query: query,
    );
    return parseReminderPage(
      decoded,
      (json) => ReminderTemplateDto.fromJson(json).value,
    );
  }

  @override
  Future<ReminderTemplate> createTemplate(ReminderTemplateDraft draft) async {
    final decoded = await _request(
      'POST',
      '/api/v1/reminder-templates',
      body: draft.toJson(),
    );
    return ReminderTemplateDto.fromJson(_object(decoded)).value;
  }

  @override
  Future<ReminderTemplate> updateTemplate(
    String templateId,
    Map<String, Object?> changes,
  ) async {
    final decoded = await _request(
      'PATCH',
      '/api/v1/reminder-templates/${Uri.encodeComponent(templateId)}',
      body: changes,
    );
    return ReminderTemplateDto.fromJson(_object(decoded)).value;
  }

  @override
  Future<ReminderTemplate> archiveTemplate(String templateId) async {
    final decoded = await _request(
      'POST',
      '/api/v1/reminder-templates/${Uri.encodeComponent(templateId)}/archive',
    );
    return ReminderTemplateDto.fromJson(_object(decoded)).value;
  }

  @override
  Future<ReminderActionResult> complete(String occurrenceId, {String? note}) =>
      _action(occurrenceId, 'complete', {'note': note?.trim()});

  @override
  Future<ReminderActionResult> snooze(
    String occurrenceId, {
    int? snoozeMinutes,
    String? note,
  }) => _action(occurrenceId, 'snooze', {
    'snooze_minutes': snoozeMinutes,
    'note': note?.trim(),
  });

  @override
  Future<ReminderActionResult> completeOnBehalf(
    String occurrenceId,
    String note,
  ) => _action(occurrenceId, 'complete-on-behalf', {'note': note.trim()});

  @override
  Future<ReminderActionResult> cancel(String occurrenceId, String note) =>
      _action(occurrenceId, 'cancel', {'note': note.trim()});

  @override
  Future<ReminderActionResult> snoozeOnBehalf(
    String occurrenceId,
    String note, {
    int? snoozeMinutes,
  }) => _action(occurrenceId, 'snooze-on-behalf', {
    'snooze_minutes': snoozeMinutes,
    'note': note.trim(),
  });

  Future<ReminderActionResult> addNote(String occurrenceId, String note) =>
      _action(occurrenceId, 'notes', {'note': note.trim()});

  Future<ReminderActionResult> followUp(String occurrenceId, String note) =>
      _action(occurrenceId, 'follow-ups', {'note': note.trim()});

  Future<ReminderActionResult> markMissedHandled(
    String occurrenceId, {
    String? note,
  }) => _action(occurrenceId, 'missed/handle', {'note': note?.trim()});

  Future<ReminderActionResult> _action(
    String occurrenceId,
    String action,
    Map<String, Object?> values,
  ) async {
    final body = <String, Object?>{
      'client_action_id': _uuidV4(),
      for (final entry in values.entries)
        if (entry.value != null) entry.key: entry.value,
    };
    final decoded = await _request(
      'POST',
      '/api/v1/reminders/${Uri.encodeComponent(occurrenceId)}/$action',
      body: body,
    );
    final object = _object(decoded);
    final reminder = object['reminder'];
    final idempotent = object['idempotent'];
    if (reminder is! Map<String, dynamic> || idempotent is! bool) {
      throw const ReminderApiFailure('The reminder response was invalid.');
    }
    return ReminderActionResult(
      reminder: ReminderOccurrenceDto.fromJson(reminder).value,
      idempotent: idempotent,
    );
  }

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Map<String, Object?>? body,
  }) async {
    final token = _session.accessToken;
    if (token == null || token.isEmpty) {
      throw const ReminderApiFailure('Please sign in again.', statusCode: 401);
    }
    final uri = Uri.parse(
      '${AppConfig.backendBaseUrl}$path',
    ).replace(queryParameters: query);
    try {
      late http.Response response;
      final headers = <String, String>{'authorization': 'Bearer $token'};
      if (body != null) headers['content-type'] = 'application/json';
      if (method == 'GET') {
        response = await _client.get(uri, headers: headers).timeout(timeout);
      } else if (method == 'POST') {
        response = await _client
            .post(
              uri,
              headers: headers,
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(timeout);
      } else if (method == 'PATCH') {
        response = await _client
            .patch(uri, headers: headers, body: jsonEncode(body))
            .timeout(timeout);
      } else {
        throw StateError('Unsupported reminder request method.');
      }
      if (_session.accessToken != token) {
        throw const ReminderApiFailure(
          'Please sign in again.',
          statusCode: 401,
        );
      }
      if (response.statusCode == 401) {
        await _session.clearInvalidSession();
        throw const ReminderApiFailure(
          'Please sign in again.',
          statusCode: 401,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ReminderApiFailure(
          _message(response.statusCode),
          statusCode: response.statusCode,
        );
      }
      try {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        throw const ReminderApiFailure('The reminder response was invalid.');
      }
    } on TimeoutException {
      throw const ReminderApiFailure('The reminder request timed out.');
    } on http.ClientException {
      throw const ReminderApiFailure(
        'Unable to reach Alera. Please try again.',
      );
    }
  }

  Map<String, dynamic> _object(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const ReminderApiFailure('The reminder response was invalid.');
    }
    return value;
  }

  String _message(int status) => switch (status) {
    403 => 'You do not have permission to manage this reminder.',
    404 => 'This reminder is no longer available.',
    409 => 'This reminder changed. Refresh and try again.',
    422 => 'Check the reminder details and try again.',
    _ => 'Unable to update reminders. Please try again.',
  };

  String _uuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
