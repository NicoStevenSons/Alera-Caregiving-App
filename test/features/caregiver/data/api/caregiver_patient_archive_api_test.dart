import 'dart:async';
import 'dart:convert';

import 'package:alera/features/caregiver/data/api/caregiver_patient_api_data_source.dart';
import 'package:alera/features/caregiver/data/api/caregiver_patient_archive_data_source.dart';
import 'package:alera/features/caregiver/data/auth/caregiver_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  CaregiverPatientApiDataSource sourceFor(
    MockClient client, {
    _FakeSession? session,
  }) => CaregiverPatientApiDataSource(
    session: session ?? _FakeSession(),
    client: client,
  );

  Matcher failure({
    CaregiverPatientFailureKind? kind,
    String? message,
    int? statusCode,
  }) {
    var matcher = isA<CaregiverPatientApiFailure>();
    if (kind != null) {
      matcher = matcher.having((e) => e.kind, 'kind', kind);
    }
    if (message != null) {
      matcher = matcher.having((e) => e.message, 'message', message);
    }
    if (statusCode != null) {
      matcher = matcher.having((e) => e.statusCode, 'statusCode', statusCode);
    }
    return matcher;
  }

  test('is the production CaregiverPatientArchiveDataSource', () {
    expect(
      sourceFor(MockClient((_) async => http.Response('', 500))),
      isA<CaregiverPatientArchiveDataSource>(),
    );
  });

  test('POSTs to /archive with bearer auth and no body', () async {
    late http.Request captured;
    final source = sourceFor(
      MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode(_archivedJson()), 200);
      }),
    );

    final result = await source.archivePatient('patient-1');

    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/v1/patients/patient-1/archive');
    expect(captured.headers['authorization'], 'Bearer caregiver-token');
    expect(captured.body, isEmpty);
    expect(captured.headers.containsKey('content-type'), isFalse);
    expect(result.patientId, 'patient-1');
    expect(result.archivedAt, DateTime.utc(2026, 10, 12, 15, 30, 5));
    expect(result.archivedAt.isUtc, isTrue);
  });

  test('normalizes a non-UTC archived_at to UTC', () async {
    final source = sourceFor(
      MockClient(
        (_) async => http.Response(
          jsonEncode(_archivedJson(archivedAt: '2026-10-12T23:30:05+08:00')),
          200,
        ),
      ),
    );

    final result = await source.archivePatient('patient-1');

    expect(result.archivedAt, DateTime.utc(2026, 10, 12, 15, 30, 5));
    expect(result.archivedAt.isUtc, isTrue);
  });

  test('retrying returns the original archive timestamp', () async {
    var calls = 0;
    final source = sourceFor(
      MockClient((_) async {
        calls++;
        return http.Response(jsonEncode(_archivedJson()), 200);
      }),
    );

    final first = await source.archivePatient('patient-1');
    final second = await source.archivePatient('patient-1');

    expect(calls, 2);
    expect(second.archivedAt, first.archivedAt);
  });

  test('encodes the patient id in the path', () async {
    late Uri url;
    final source = sourceFor(
      MockClient((request) async {
        url = request.url;
        return http.Response(jsonEncode(_archivedJson()), 200);
      }),
    );

    await source.archivePatient('a/b c');

    expect(url.path, '/api/v1/patients/a%2Fb%20c/archive');
  });

  test('malformed 200 responses are malformed failures', () async {
    for (final body in const [
      'not json',
      '[]',
      '{}',
      '{"patient_id": "patient-1"}',
      '{"patient_id": "patient-1", "archived_at": "yesterday"}',
    ]) {
      final source = sourceFor(
        MockClient((_) async => http.Response(body, 200)),
      );
      await expectLater(
        source.archivePatient('patient-1'),
        throwsA(failure(kind: CaregiverPatientFailureKind.malformed)),
        reason: body,
      );
    }
  });

  test('401 clears the session and asks to sign in again', () async {
    final session = _FakeSession();
    final source = sourceFor(
      MockClient(
        (_) async => http.Response(jsonEncode({'detail': 'Bad token'}), 401),
      ),
      session: session,
    );

    await expectLater(
      source.archivePatient('patient-1'),
      throwsA(
        failure(
          kind: CaregiverPatientFailureKind.unauthorized,
          message: 'Please sign in again.',
          statusCode: 401,
        ),
      ),
    );
    expect(session.cleared, isTrue);
  });

  test('missing token fails without calling the network', () async {
    var called = false;
    final source = sourceFor(
      MockClient((_) async {
        called = true;
        return http.Response('', 200);
      }),
      session: _FakeSession(token: null),
    );

    await expectLater(
      source.archivePatient('patient-1'),
      throwsA(failure(message: 'Please sign in again.')),
    );
    expect(called, isFalse);
  });

  test('403 prefers the backend detail', () async {
    final source = sourceFor(
      MockClient(
        (_) async => http.Response(
          jsonEncode({'detail': 'Caregiver role required.'}),
          403,
        ),
      ),
    );

    await expectLater(
      source.archivePatient('patient-1'),
      throwsA(
        failure(
          kind: CaregiverPatientFailureKind.forbidden,
          message: 'Caregiver role required.',
          statusCode: 403,
        ),
      ),
    );
  });

  test('403 without a detail uses a clear fallback', () async {
    final source = sourceFor(MockClient((_) async => http.Response('', 403)));

    await expectLater(
      source.archivePatient('patient-1'),
      throwsA(
        failure(
          kind: CaregiverPatientFailureKind.forbidden,
          message: 'You do not have permission to archive this patient.',
        ),
      ),
    );
  });

  test('404 prefers the backend detail, then falls back', () async {
    final withDetail = sourceFor(
      MockClient(
        (_) async =>
            http.Response(jsonEncode({'detail': 'Patient not found'}), 404),
      ),
    );
    await expectLater(
      withDetail.archivePatient('patient-1'),
      throwsA(
        failure(
          kind: CaregiverPatientFailureKind.notFound,
          message: 'Patient not found',
          statusCode: 404,
        ),
      ),
    );

    final bare = sourceFor(MockClient((_) async => http.Response('', 404)));
    await expectLater(
      bare.archivePatient('patient-1'),
      throwsA(
        failure(
          kind: CaregiverPatientFailureKind.notFound,
          message: 'Patient not found.',
        ),
      ),
    );
  });

  test('422 shows the backend validation message', () async {
    final source = sourceFor(
      MockClient(
        (_) async => http.Response(
          jsonEncode({
            'detail': [
              {
                'loc': ['path', 'patient_id'],
                'msg': 'Input should be a valid UUID',
                'type': 'uuid_parsing',
              },
            ],
          }),
          422,
        ),
      ),
    );

    await expectLater(
      source.archivePatient('not-a-uuid'),
      throwsA(
        failure(message: 'Input should be a valid UUID', statusCode: 422),
      ),
    );
  });

  test('5xx is a server failure that does not leak the body', () async {
    final source = sourceFor(
      MockClient((_) async => http.Response('Traceback (most recent', 503)),
    );

    await expectLater(
      source.archivePatient('patient-1'),
      throwsA(
        failure(
          kind: CaregiverPatientFailureKind.server,
          message: 'The server is temporarily unavailable.',
          statusCode: 503,
        ),
      ),
    );
  });

  test('connection errors and timeouts are connectivity failures', () async {
    for (final error in <Object>[
      http.ClientException('offline'),
      TimeoutException('slow'),
    ]) {
      final source = sourceFor(MockClient((_) async => throw error));
      await expectLater(
        source.archivePatient('patient-1'),
        throwsA(failure(kind: CaregiverPatientFailureKind.connectivity)),
        reason: '$error',
      );
    }
  });
}

Map<String, dynamic> _archivedJson({
  String archivedAt = '2026-10-12T15:30:05Z',
}) => {'patient_id': 'patient-1', 'archived_at': archivedAt};

class _FakeSession implements CaregiverSession {
  _FakeSession({this.token = 'caregiver-token'});
  final String? token;
  bool cleared = false;
  @override
  String? get accessToken => token;
  @override
  String? get householdCode => 'HOME-123';
  @override
  Future<void> clearInvalidSession() async => cleared = true;
}
