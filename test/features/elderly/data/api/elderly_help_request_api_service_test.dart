import 'dart:convert';
import 'dart:math';

import 'package:alera/features/caregiver/data/auth/caregiver_session_controller.dart';
import 'package:alera/features/elderly/data/api/elderly_help_request_api_service.dart';
import 'package:alera/features/help_requests/domain/help_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('fetchActive returns the authenticated patient request', () async {
    late http.Request captured;

    final service = ElderlyHelpRequestApiService(
      session: _Session('patient-token'),
      client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode(_helpRequestJson()), 200);
      }),
    );

    final request = await service.fetchActive();

    expect(captured.method, 'GET');
    expect(captured.url.path, '/api/v1/help-requests/active');
    expect(captured.headers['authorization'], 'Bearer patient-token');
    expect(request?.id, 'help-request-id');
    expect(request?.status, HelpRequestStatus.pending);
    expect(request?.requestedAt.isUtc, isTrue);
  });

  test('fetchActive returns null when no request is active', () async {
    final service = ElderlyHelpRequestApiService(
      session: _Session('patient-token'),
      client: MockClient((_) async => http.Response('null', 200)),
    );

    expect(await service.fetchActive(), isNull);
  });

  test('create sends caller action id and trims the message', () async {
    late http.Request captured;

    final service = ElderlyHelpRequestApiService(
      session: _Session('patient-token'),
      client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode(_helpRequestJson()), 201);
      }),
    );

    final result = await service.create(
      clientActionId: 'client-action-id',
      message: '  Please call me  ',
    );

    final body = jsonDecode(captured.body) as Map<String, dynamic>;

    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/v1/help-requests');
    expect(body, {
      'client_action_id': 'client-action-id',
      'message': 'Please call me',
    });
    expect(result.idempotent, isFalse);
  });

  test('create omits a blank optional message', () async {
    late http.Request captured;

    final service = ElderlyHelpRequestApiService(
      session: _Session('patient-token'),
      client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode(_helpRequestJson(message: null)), 201);
      }),
    );

    await service.create(clientActionId: 'client-action-id', message: '   ');

    final body = jsonDecode(captured.body) as Map<String, dynamic>;

    expect(body, {'client_action_id': 'client-action-id'});
  });

  test('creates valid UUID v4 action ids', () {
    final service = ElderlyHelpRequestApiService(
      session: _Session('patient-token'),
      random: Random(42),
      client: MockClient((_) async => http.Response('null', 200)),
    );

    expect(
      service.createActionId(),
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
          r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('rejects invalid response data and unknown statuses', () async {
    final service = ElderlyHelpRequestApiService(
      session: _Session('patient-token'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode(_helpRequestJson(status: 'SURPRISE')),
          200,
        ),
      ),
    );

    await expectLater(
      service.fetchActive(),
      throwsA(
        isA<ElderlyHelpRequestApiFailure>().having(
          (error) => error.message,
          'message',
          'The help request response was invalid.',
        ),
      ),
    );
  });

  test('401 clears the captured invalid patient session', () async {
    final session = _Session('expired-token');

    final service = ElderlyHelpRequestApiService(
      session: session,
      client: MockClient((_) async => http.Response('{}', 401)),
    );

    await expectLater(
      service.fetchActive(),
      throwsA(
        isA<ElderlyHelpRequestApiFailure>().having(
          (error) => error.statusCode,
          'status',
          401,
        ),
      ),
    );

    expect(session.cleared, isTrue);
    expect(session.accessToken, isNull);
  });

  test('late response cannot clear a replacement session', () async {
    final session = _Session('old-token');

    final service = ElderlyHelpRequestApiService(
      session: session,
      client: MockClient((_) async {
        session.accessToken = 'replacement-token';
        return http.Response('{}', 401);
      }),
    );

    await expectLater(
      service.fetchActive(),
      throwsA(
        isA<ElderlyHelpRequestApiFailure>().having(
          (error) => error.statusCode,
          'status',
          401,
        ),
      ),
    );

    expect(session.cleared, isFalse);
    expect(session.accessToken, 'replacement-token');
  });

  test('409 explains that an active request already exists', () async {
    final service = ElderlyHelpRequestApiService(
      session: _Session('patient-token'),
      client: MockClient((_) async => http.Response('{}', 409)),
    );

    await expectLater(
      service.create(clientActionId: 'client-action-id'),
      throwsA(
        isA<ElderlyHelpRequestApiFailure>()
            .having((error) => error.statusCode, 'status', 409)
            .having(
              (error) => error.message,
              'message',
              'You already have an active help request.',
            ),
      ),
    );
  });

  test('missing token fails without making a request', () async {
    var requests = 0;

    final service = ElderlyHelpRequestApiService(
      session: _Session(null),
      client: MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );

    await expectLater(
      service.fetchActive(),
      throwsA(
        isA<ElderlyHelpRequestApiFailure>().having(
          (error) => error.statusCode,
          'status',
          401,
        ),
      ),
    );

    expect(requests, 0);
  });
}

Map<String, dynamic> _helpRequestJson({
  String status = 'PENDING',
  String? message = 'Please call me',
}) {
  return {
    'help_request_id': 'help-request-id',
    'patient_id': 'patient-id',
    'status': status,
    'message': message,
    'client_action_id': 'client-action-id',
    'requested_at': '2026-10-05T02:00:00Z',
    'acknowledged_by_user_id': null,
    'acknowledged_at': null,
    'resolved_by_user_id': null,
    'resolved_at': null,
    'updated_at': '2026-10-05T02:00:00Z',
    'patient_display_name': 'Test Patient',
    'idempotent': false,
  };
}

class _Session implements CaregiverSession {
  _Session(this.accessToken);

  @override
  String? accessToken;

  bool cleared = false;

  @override
  String? get householdCode => null;

  @override
  Future<void> clearInvalidSession() async {
    cleared = true;
    accessToken = null;
  }
}
