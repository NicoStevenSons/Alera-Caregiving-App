import 'dart:async';
import 'dart:convert';

import 'package:alera/features/caregiver/data/api/caregiver_help_request_api_data_source.dart';
import 'package:alera/features/caregiver/data/auth/caregiver_session_controller.dart';
import 'package:alera/features/help_requests/domain/help_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'lists active requests with repeated statuses and patient filter',
    () async {
      late http.Request captured;

      final source = CaregiverHelpRequestApiDataSource(
        session: _Session('caregiver-token'),
        client: MockClient((request) async {
          captured = request;

          return http.Response(
            jsonEncode({
              'items': [_helpRequestJson()],
              'total': 1,
              'limit': 25,
              'offset': 0,
            }),
            200,
          );
        }),
      );

      final page = await source.fetchRequests(
        statuses: const [
          HelpRequestStatus.pending,
          HelpRequestStatus.acknowledged,
        ],
        patientId: 'patient-id',
        limit: 25,
      );

      expect(captured.method, 'GET');
      expect(captured.url.path, '/api/v1/help-requests');
      expect(captured.headers['authorization'], 'Bearer caregiver-token');
      expect(captured.url.queryParametersAll['status'], [
        'PENDING',
        'ACKNOWLEDGED',
      ]);
      expect(captured.url.queryParameters['patient_id'], 'patient-id');
      expect(page.total, 1);
      expect(page.items.single.patientDisplayName, 'Nana');
      expect(page.items.single.status, HelpRequestStatus.pending);
    },
  );

  test('fetches one exact assigned help request', () async {
    late http.Request captured;

    final source = CaregiverHelpRequestApiDataSource(
      session: _Session('caregiver-token'),
      client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode(_helpRequestJson()), 200);
      }),
    );

    final request = await source.fetchRequest('request-id');

    expect(captured.method, 'GET');
    expect(captured.url.path, '/api/v1/help-requests/request-id');
    expect(request.id, 'request-id');
  });

  test('acknowledges and resolves through their exact action paths', () async {
    final captured = <http.Request>[];

    final source = CaregiverHelpRequestApiDataSource(
      session: _Session('caregiver-token'),
      client: MockClient((request) async {
        captured.add(request);

        final resolved = request.url.path.endsWith('/resolve');

        return http.Response(
          jsonEncode(
            _helpRequestJson(
              status: resolved ? 'RESOLVED' : 'ACKNOWLEDGED',
              acknowledgedAt: resolved
                  ? '2026-10-05T02:05:00Z'
                  : '2026-10-05T02:05:00Z',
              resolvedAt: resolved ? '2026-10-05T02:10:00Z' : null,
            ),
          ),
          200,
        );
      }),
    );

    final acknowledged = await source.acknowledge('request-id');
    final resolved = await source.resolve('request-id');

    expect(captured, hasLength(2));
    expect(captured[0].method, 'POST');
    expect(
      captured[0].url.path,
      '/api/v1/help-requests/request-id/acknowledge',
    );
    expect(captured[1].url.path, '/api/v1/help-requests/request-id/resolve');
    expect(acknowledged.status, HelpRequestStatus.acknowledged);
    expect(resolved.status, HelpRequestStatus.resolved);
  });

  test('rejects a substituted detail response', () async {
    final source = CaregiverHelpRequestApiDataSource(
      session: _Session('token'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode(_helpRequestJson(id: 'different-request')),
          200,
        ),
      ),
    );

    await expectLater(
      source.fetchRequest('requested-id'),
      throwsA(isA<CaregiverHelpRequestFailure>()),
    );
  });

  test('rejects malformed pagination instead of guessing', () async {
    final source = CaregiverHelpRequestApiDataSource(
      session: _Session('token'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'items': [_helpRequestJson()],
            'total': 'one',
            'limit': 100,
            'offset': 0,
          }),
          200,
        ),
      ),
    );

    await expectLater(
      source.fetchRequests(),
      throwsA(
        isA<CaregiverHelpRequestFailure>().having(
          (error) => error.message,
          'message',
          'The help-request response was invalid.',
        ),
      ),
    );
  });

  test('401 clears the captured invalid caregiver session', () async {
    final session = _Session('expired-token');

    final source = CaregiverHelpRequestApiDataSource(
      session: session,
      client: MockClient((_) async => http.Response('{}', 401)),
    );

    await expectLater(
      source.fetchRequests(),
      throwsA(
        isA<CaregiverHelpRequestFailure>().having(
          (error) => error.statusCode,
          'status',
          401,
        ),
      ),
    );

    expect(session.cleared, isTrue);
    expect(session.accessToken, isNull);
  });

  test('late response cannot clear a replacement caregiver session', () async {
    final session = _Session('old-token');
    final completion = Completer<http.Response>();

    final source = CaregiverHelpRequestApiDataSource(
      session: session,
      client: MockClient((_) => completion.future),
    );

    final request = source.fetchRequests();
    session.accessToken = 'replacement-token';
    completion.complete(http.Response('{}', 401));

    await expectLater(
      request,
      throwsA(
        isA<CaregiverHelpRequestFailure>().having(
          (error) => error.statusCode,
          'status',
          401,
        ),
      ),
    );

    expect(session.cleared, isFalse);
    expect(session.accessToken, 'replacement-token');
  });

  test('409 preserves a useful transition-conflict message', () async {
    final source = CaregiverHelpRequestApiDataSource(
      session: _Session('token'),
      client: MockClient((_) async => http.Response('{}', 409)),
    );

    await expectLater(
      source.acknowledge('request-id'),
      throwsA(
        isA<CaregiverHelpRequestFailure>()
            .having((error) => error.statusCode, 'status', 409)
            .having(
              (error) => error.message,
              'message',
              'This help request has already changed.',
            ),
      ),
    );
  });

  test('creates a valid UUID-v4 note action id', () {
    final source = CaregiverHelpRequestApiDataSource(
      session: _Session('token'),
    );

    final actionId = source.createNoteActionId();

    expect(
      actionId,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
          r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('lists caregiver notes with pagination and attribution', () async {
    late http.Request captured;

    final source = CaregiverHelpRequestApiDataSource(
      session: _Session('caregiver-token'),
      client: MockClient((request) async {
        captured = request;

        return http.Response(
          jsonEncode({
            'items': [_helpRequestNoteJson()],
            'total': 1,
            'limit': 25,
            'offset': 5,
          }),
          200,
        );
      }),
    );

    final page = await source.fetchNotes('request-id', limit: 25, offset: 5);

    expect(captured.method, 'GET');
    expect(captured.url.path, '/api/v1/help-requests/request-id/notes');
    expect(captured.url.queryParameters['limit'], '25');
    expect(captured.url.queryParameters['offset'], '5');
    expect(captured.headers['authorization'], 'Bearer caregiver-token');

    expect(page.total, 1);
    expect(page.limit, 25);
    expect(page.offset, 5);
    expect(page.items.single.id, 'note-id');
    expect(page.items.single.helpRequestId, 'request-id');
    expect(page.items.single.authorDisplayName, 'Caregiver Ana');
    expect(page.items.single.note, 'Called Nana.');
  });

  test('adds a trimmed caregiver note with JSON body', () async {
    late http.Request captured;

    final source = CaregiverHelpRequestApiDataSource(
      session: _Session('caregiver-token'),
      client: MockClient((request) async {
        captured = request;

        return http.Response(
          jsonEncode(
            _helpRequestNoteJson(
              clientActionId: 'note-action-id',
              note: 'Called Nana.',
            ),
          ),
          201,
        );
      }),
    );

    final note = await source.addNote(
      'request-id',
      clientActionId: 'note-action-id',
      note: '  Called Nana.  ',
    );

    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/v1/help-requests/request-id/notes');
    expect(captured.headers['content-type'], contains('application/json'));
    expect(jsonDecode(captured.body), {
      'client_action_id': 'note-action-id',
      'note': 'Called Nana.',
    });

    expect(note.helpRequestId, 'request-id');
    expect(note.clientActionId, 'note-action-id');
    expect(note.note, 'Called Nana.');
  });

  test('rejects a note belonging to another help request', () async {
    final source = CaregiverHelpRequestApiDataSource(
      session: _Session('token'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'items': [_helpRequestNoteJson(helpRequestId: 'different-request')],
            'total': 1,
            'limit': 50,
            'offset': 0,
          }),
          200,
        ),
      ),
    );

    await expectLater(
      source.fetchNotes('request-id'),
      throwsA(
        isA<CaregiverHelpRequestFailure>().having(
          (error) => error.message,
          'message',
          'The help-request response was invalid.',
        ),
      ),
    );
  });

  test('rejects a substituted note creation response', () async {
    final source = CaregiverHelpRequestApiDataSource(
      session: _Session('token'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode(_helpRequestNoteJson(clientActionId: 'different-action')),
          201,
        ),
      ),
    );

    await expectLater(
      source.addNote(
        'request-id',
        clientActionId: 'expected-action',
        note: 'Called Nana.',
      ),
      throwsA(isA<CaregiverHelpRequestFailure>()),
    );
  });
}

Map<String, dynamic> _helpRequestJson({
  String id = 'request-id',
  String status = 'PENDING',
  String? acknowledgedAt,
  String? resolvedAt,
}) {
  return {
    'help_request_id': id,
    'patient_id': 'patient-id',
    'status': status,
    'message': 'Please call me',
    'client_action_id': 'client-action-id',
    'requested_at': '2026-10-05T02:00:00Z',
    'acknowledged_by_user_id': acknowledgedAt == null ? null : 'caregiver-id',
    'acknowledged_at': acknowledgedAt,
    'resolved_by_user_id': resolvedAt == null ? null : 'caregiver-id',
    'resolved_at': resolvedAt,
    'updated_at': '2026-10-05T02:10:00Z',
    'patient_display_name': 'Nana',
    'idempotent': false,
  };
}

Map<String, dynamic> _helpRequestNoteJson({
  String id = 'note-id',
  String helpRequestId = 'request-id',
  String authorUserId = 'caregiver-id',
  String clientActionId = 'note-action-id',
  String note = 'Called Nana.',
  String? authorDisplayName = 'Caregiver Ana',
  bool idempotent = false,
}) {
  return {
    'help_request_note_id': id,
    'help_request_id': helpRequestId,
    'author_user_id': authorUserId,
    'client_action_id': clientActionId,
    'note': note,
    'created_at': '2026-10-06T14:30:00Z',
    'author_display_name': authorDisplayName,
    'idempotent': idempotent,
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
