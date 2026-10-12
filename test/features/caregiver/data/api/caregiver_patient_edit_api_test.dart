import 'dart:convert';

import 'package:alera/features/caregiver/data/api/caregiver_patient_api_data_source.dart';
import 'package:alera/features/caregiver/data/api/caregiver_patient_edit_data_source.dart';
import 'package:alera/features/caregiver/data/api/dto/patient_dto.dart';
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

  test('is the production CaregiverPatientEditDataSource', () {
    expect(
      sourceFor(MockClient((_) async => http.Response('', 500))),
      isA<CaregiverPatientEditDataSource>(),
    );
  });

  test('PATCHes the patient with bearer auth and the full payload', () async {
    late http.Request captured;
    final source = sourceFor(
      MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode(_detailJson()), 200);
      }),
    );

    final saved = await source.updatePatient(
      'patient-1',
      UpdatePatientRequest(
        fullName: ' Maria Santos ',
        birthdate: DateTime(1950, 2, 3),
        sex: 'FEMALE',
        phoneNumber: '09123456789',
        addressOrRoom: 'Room 4',
        emergencyContactName: 'Juan',
        emergencyContactPhone: '555-0100',
        knownConditions: 'Hypertension',
        medications: 'Medication A',
        monitoringNotes: 'Morning checks',
        relationshipLabel: ' Mother ',
      ),
    );

    expect(captured.method, 'PATCH');
    expect(captured.url.path, '/api/v1/patients/patient-1');
    expect(captured.headers['authorization'], 'Bearer caregiver-token');
    expect(captured.headers['content-type'], contains('application/json'));
    expect(jsonDecode(captured.body), {
      'full_name': 'Maria Santos',
      'birthdate': '1950-02-03',
      'sex': 'FEMALE',
      'phone_number': '09123456789',
      'address_or_room': 'Room 4',
      'emergency_contact_name': 'Juan',
      'emergency_contact_phone': '555-0100',
      'known_conditions': 'Hypertension',
      'medications': 'Medication A',
      'monitoring_notes': 'Morning checks',
      'relationship_label': 'Mother',
    });
    expect(saved.patientId, 'patient-1');
  });

  test('never sends monitoring thresholds or baselines', () async {
    late Map<String, dynamic> body;
    final source = sourceFor(
      MockClient((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode(_detailJson()), 200);
      }),
    );

    await source.updatePatient(
      'patient-1',
      const UpdatePatientRequest(fullName: 'Maria'),
    );

    for (final key in const [
      'normal_hr_min',
      'normal_hr_max',
      'usual_spo2_min',
      'usual_spo2_max',
      'threshold_mode',
      'baseline_heart_rate',
      'baseline_spo2',
    ]) {
      expect(body.containsKey(key), isFalse, reason: key);
    }
  });

  test('clearing optional fields sends explicit nulls', () async {
    late Map<String, dynamic> body;
    final source = sourceFor(
      MockClient((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode(_detailJson()), 200);
      }),
    );

    await source.updatePatient(
      'patient-1',
      const UpdatePatientRequest(
        fullName: 'Maria',
        phoneNumber: '   ',
        addressOrRoom: '',
        relationshipLabel: '   ',
      ),
    );

    expect(body['full_name'], 'Maria');
    for (final key in const [
      'birthdate',
      'sex',
      'phone_number',
      'address_or_room',
      'emergency_contact_name',
      'emergency_contact_phone',
      'known_conditions',
      'medications',
      'monitoring_notes',
      'relationship_label',
    ]) {
      expect(body.containsKey(key), isTrue, reason: '$key must be present');
      expect(body[key], isNull, reason: '$key must be an explicit null');
    }
  });

  test('encodes the patient id in the path', () async {
    late Uri url;
    final source = sourceFor(
      MockClient((request) async {
        url = request.url;
        return http.Response(jsonEncode(_detailJson()), 200);
      }),
    );

    await source.updatePatient(
      'a/b c',
      const UpdatePatientRequest(fullName: 'Maria'),
    );

    expect(url.path, '/api/v1/patients/a%2Fb%20c');
  });

  test('parses the returned patient detail incl. relationship', () async {
    final source = sourceFor(
      MockClient(
        (_) async => http.Response(
          jsonEncode(
            _detailJson(
              fullName: 'Maria Santos',
              relationship: '  Mother ',
              address: 'Room 9',
            ),
          ),
          200,
        ),
      ),
    );

    final saved = await source.updatePatient(
      'patient-1',
      const UpdatePatientRequest(fullName: 'Maria Santos'),
    );

    expect(saved.fullName, 'Maria Santos');
    expect(saved.addressOrRoom, 'Room 9');
    expect(saved.relationshipLabel, 'Mother');
  });

  test('a null relationship_label in the response stays unset', () async {
    final source = sourceFor(
      MockClient((_) async => http.Response(jsonEncode(_detailJson()), 200)),
    );

    final saved = await source.updatePatient(
      'patient-1',
      const UpdatePatientRequest(fullName: 'Maria'),
    );

    expect(saved.relationshipLabel, isNull);
  });

  test('malformed responses become a malformed failure', () async {
    for (final body in const ['not json', '[]', '{"patient_id": 3}']) {
      final source = sourceFor(
        MockClient((_) async => http.Response(body, 200)),
      );
      await expectLater(
        source.updatePatient(
          'patient-1',
          const UpdatePatientRequest(fullName: 'Maria'),
        ),
        throwsA(
          isA<CaregiverPatientApiFailure>().having(
            (e) => e.kind,
            'kind',
            CaregiverPatientFailureKind.malformed,
          ),
        ),
        reason: body,
      );
    }
  });

  test('401 clears the session and asks to sign in again', () async {
    final session = _FakeSession();
    final source = sourceFor(
      MockClient((_) async => http.Response('', 401)),
      session: session,
    );

    await expectLater(
      source.updatePatient(
        'patient-1',
        const UpdatePatientRequest(fullName: 'Maria'),
      ),
      throwsA(
        isA<CaregiverPatientApiFailure>()
            .having(
              (e) => e.kind,
              'kind',
              CaregiverPatientFailureKind.unauthorized,
            )
            .having((e) => e.message, 'message', 'Please sign in again.'),
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
      source.updatePatient(
        'patient-1',
        const UpdatePatientRequest(fullName: 'Maria'),
      ),
      throwsA(isA<CaregiverPatientApiFailure>()),
    );
    expect(called, isFalse);
  });

  test('403 says the caregiver cannot edit this patient', () async {
    final source = sourceFor(MockClient((_) async => http.Response('', 403)));

    await expectLater(
      source.updatePatient(
        'patient-1',
        const UpdatePatientRequest(fullName: 'Maria'),
      ),
      throwsA(
        isA<CaregiverPatientApiFailure>()
            .having(
              (e) => e.kind,
              'kind',
              CaregiverPatientFailureKind.forbidden,
            )
            .having(
              (e) => e.message,
              'message',
              'You do not have permission to edit this patient.',
            ),
      ),
    );
  });

  test('404 is a typed not-found failure', () async {
    final source = sourceFor(MockClient((_) async => http.Response('', 404)));

    await expectLater(
      source.updatePatient(
        'patient-1',
        const UpdatePatientRequest(fullName: 'Maria'),
      ),
      throwsA(
        isA<CaregiverPatientApiFailure>()
            .having((e) => e.kind, 'kind', CaregiverPatientFailureKind.notFound)
            .having((e) => e.message, 'message', 'Patient not found.'),
      ),
    );
  });

  test('422 surfaces the safe validation message', () async {
    final source = sourceFor(
      MockClient(
        (_) async => http.Response(
          jsonEncode({
            'detail': [
              {
                'loc': ['body', 'phone_number'],
                'msg': 'Phone number is too long',
                'type': 'string_too_long',
              },
            ],
          }),
          422,
        ),
      ),
    );

    await expectLater(
      source.updatePatient(
        'patient-1',
        const UpdatePatientRequest(fullName: 'Maria'),
      ),
      throwsA(
        isA<CaregiverPatientApiFailure>().having(
          (e) => e.message,
          'message',
          'Phone number is too long',
        ),
      ),
    );
  });

  test('5xx is a server failure with a friendly message', () async {
    final source = sourceFor(
      MockClient((_) async => http.Response('boom', 503)),
    );

    await expectLater(
      source.updatePatient(
        'patient-1',
        const UpdatePatientRequest(fullName: 'Maria'),
      ),
      throwsA(
        isA<CaregiverPatientApiFailure>()
            .having((e) => e.kind, 'kind', CaregiverPatientFailureKind.server)
            .having(
              (e) => e.message,
              'message',
              'The server is temporarily unavailable.',
            ),
      ),
    );
  });

  test('connection errors are connectivity failures', () async {
    final source = sourceFor(
      MockClient((_) async => throw http.ClientException('offline')),
    );

    await expectLater(
      source.updatePatient(
        'patient-1',
        const UpdatePatientRequest(fullName: 'Maria'),
      ),
      throwsA(
        isA<CaregiverPatientApiFailure>().having(
          (e) => e.kind,
          'kind',
          CaregiverPatientFailureKind.connectivity,
        ),
      ),
    );
  });
}

Map<String, dynamic> _detailJson({
  String fullName = 'Ada',
  String? relationship,
  String? address = 'Room 4',
}) => {
  'patient_id': 'patient-1',
  'user_id': 'user-1',
  'household_id': 'household-1',
  'full_name': fullName,
  'birthdate': null,
  'sex': null,
  'phone_number': null,
  'address_or_room': address,
  'account_status': 'ACTIVE',
  'created_at': '2026-09-06T10:00:00Z',
  'relationship_label': relationship,
  'current_summary': {
    'latest_heart_rate': null,
    'latest_spo2': null,
    'last_check_in': null,
    'active_alert_count': 0,
    'highest_active_alert_severity': null,
    'monitoring_status': 'NO_DATA',
    'device_connection_status': 'NOT_CONNECTED',
    'last_device_sync_at': null,
  },
  'emergency_contact_name': null,
  'emergency_contact_phone': null,
  'known_conditions': null,
  'medications': null,
  'baseline_heart_rate': null,
  'baseline_spo2': null,
  'monitoring_notes': null,
  'archived_at': null,
  'assignment': null,
  'normal_hr_min': 60,
  'normal_hr_max': 100,
  'usual_spo2_min': 95,
  'usual_spo2_max': null,
  'threshold_mode': 'DEFAULT',
  'patient_access': {
    'status': 'NOT_CONNECTED',
    'pending_access_code_id': null,
    'pending_expires_at': null,
    'connected_at': null,
  },
};

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
