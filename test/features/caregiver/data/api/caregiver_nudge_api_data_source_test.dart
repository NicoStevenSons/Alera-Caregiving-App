import 'dart:convert';
import 'dart:math';

import 'package:alera/features/caregiver/data/api/caregiver_nudge_api_data_source.dart';
import 'package:alera/features/caregiver/data/auth/caregiver_session_controller.dart';
import 'package:alera/features/caregiver/domain/models/caregiver_nudge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('posts a typed nudge with a UUID idempotency key', () async {
    late http.Request captured;
    final source = CaregiverNudgeApiDataSource(
      client: MockClient((request) async {
        captured = request;
        return http.Response('{}', 201);
      }),
      session: _Session('caregiver-token'),
      random: Random(42),
    );

    await source.sendNudge(
      '12345678-1234-4234-9234-123456789abc',
      CaregiverNudgeType.checkBloodPressure,
    );

    expect(captured.method, 'POST');
    expect(
      captured.url.path,
      '/api/v1/patients/12345678-1234-4234-9234-123456789abc/nudges',
    );
    expect(captured.headers['authorization'], 'Bearer caregiver-token');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['nudge_type'], 'CHECK_BLOOD_PRESSURE');
    expect(
      body['client_action_id'],
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('401 clears the session and exposes safe feedback', () async {
    final session = _Session('expired');
    final source = CaregiverNudgeApiDataSource(
      client: MockClient((_) async => http.Response('{}', 401)),
      session: session,
    );

    await expectLater(
      source.sendNudge('patient', CaregiverNudgeType.drinkWater),
      throwsA(
        isA<CaregiverNudgeFailure>()
            .having((failure) => failure.statusCode, 'statusCode', 401)
            .having(
              (failure) => failure.message,
              'message',
              'Please sign in again.',
            ),
      ),
    );
    expect(session.cleared, isTrue);
  });

  test('assignment and server failures do not leak response bodies', () async {
    for (final status in [403, 404, 500]) {
      final source = CaregiverNudgeApiDataSource(
        client: MockClient(
          (_) async => http.Response('private database details', status),
        ),
        session: _Session('token'),
      );
      try {
        await source.sendNudge('patient', CaregiverNudgeType.takeMedication);
        fail('Expected CaregiverNudgeFailure');
      } on CaregiverNudgeFailure catch (failure) {
        expect(failure.message, isNot(contains('private database details')));
        expect(failure.statusCode, status);
      }
    }
  });
}

class _Session implements CaregiverSession {
  @override
  String? accessToken;
  bool cleared = false;

  _Session(this.accessToken);

  @override
  String? get householdCode => 'TEST-HOME';

  @override
  Future<void> clearInvalidSession() async {
    cleared = true;
    accessToken = null;
  }
}
