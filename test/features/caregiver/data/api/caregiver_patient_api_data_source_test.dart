import 'dart:convert';

import 'package:alera/features/caregiver/data/api/caregiver_patient_api_data_source.dart';
import 'package:alera/features/caregiver/data/api/dto/patient_dto.dart';
import 'package:alera/features/caregiver/data/auth/caregiver_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('serializes the complete create-patient request', () {
    final json = CreatePatientRequest(
      fullName: ' Ada Lovelace ',
      birthdate: DateTime(1950, 2, 3),
      sex: 'FEMALE',
      phoneNumber: '09123456789',
      addressOrRoom: 'Room 4',
      emergencyContactName: 'Charles',
      emergencyContactPhone: '555-0100',
      knownConditions: 'Hypertension',
      medications: 'Medication A',
      baselineHeartRate: 72,
      baselineSpo2: 98.5,
      monitoringNotes: 'Morning checks',
    ).toJson();

    expect(json, {
      'full_name': 'Ada Lovelace',
      'birthdate': '1950-02-03',
      'sex': 'FEMALE',
      'phone_number': '09123456789',
      'address_or_room': 'Room 4',
      'emergency_contact_name': 'Charles',
      'emergency_contact_phone': '555-0100',
      'known_conditions': 'Hypertension',
      'medications': 'Medication A',
      'baseline_heart_rate': 72,
      'baseline_spo2': 98.5,
      'monitoring_notes': 'Morning checks',
    });
  });

  test('parses Decimal fields from JSON numbers and strings', () {
    final number = PatientCreatedResponse.fromJson(
      _patientJson(heartRate: 72, spo2: 98.5),
    );
    final string = PatientCreatedResponse.fromJson(
      _patientJson(heartRate: '73.25', spo2: '99'),
    );

    expect(number.baselineHeartRate, 72);
    expect(number.baselineSpo2, 98.5);
    expect(string.baselineHeartRate, 73.25);
    expect(string.baselineSpo2, 99);
    expect(string.assignment, isNull);
  });

  test('creates patient with caregiver bearer authorization', () async {
    final session = _FakeSession();
    final source = CaregiverPatientApiDataSource(
      session: session,
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/patients');
        expect(request.headers['authorization'], 'Bearer caregiver-token');
        expect(jsonDecode(request.body)['full_name'], 'Ada');
        return http.Response(jsonEncode(_patientJson()), 201);
      }),
    );

    final result = await source.createPatient(
      const CreatePatientRequest(fullName: 'Ada'),
    );
    expect(result.patientId, 'patient-1');
  });

  test('reads authenticated patient pagination and nullable summary', () async {
    final source = CaregiverPatientApiDataSource(
      session: _FakeSession(),
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.queryParameters, {'limit': '100', 'offset': '0'});
        expect(request.headers['authorization'], 'Bearer caregiver-token');
        return http.Response(
          jsonEncode({
            'items': [_listPatientJson()],
            'total': 1,
            'limit': 100,
            'offset': 0,
          }),
          200,
        );
      }),
    );
    final page = await source.fetchPatients();
    expect(page.total, 1);
    expect(page.items.single.currentSummary.latestHeartRate, isNull);
    expect(page.items.single.currentSummary.lastCheckIn, isNull);
    expect(
      page.items.single.currentSummary.monitoringStatus,
      PatientMonitoringStatus.noData,
    );
  });

  test('list reading parses Decimal number and string forms', () async {
    final json = _listPatientJson();
    final summary = json['current_summary'] as Map<String, dynamic>;
    summary['latest_heart_rate'] = {
      'value': 72.5,
      'unit': 'bpm',
      'recorded_at': '2026-09-06T10:00:00Z',
    };
    summary['latest_spo2'] = {
      'value': '98.25',
      'unit': '%',
      'recorded_at': '2026-09-06T10:01:00+00:00',
    };
    final item = PatientListItemDto.fromJson(json);
    expect(item.currentSummary.latestHeartRate!.value, 72.5);
    expect(item.currentSummary.latestSpo2!.value, 98.25);
    expect(item.currentSummary.latestSpo2!.recordedAt.isUtc, isTrue);
  });

  test(
    '403 is authorization failure without fallback classification',
    () async {
      final source = CaregiverPatientApiDataSource(
        session: _FakeSession(),
        client: MockClient((_) async => http.Response('', 403)),
      );
      await expectLater(
        source.fetchPatients(),
        throwsA(
          isA<CaregiverPatientApiFailure>().having(
            (e) => e.kind,
            'kind',
            CaregiverPatientFailureKind.forbidden,
          ),
        ),
      );
    },
  );

  test('malformed list response is not fallback-eligible', () async {
    final source = CaregiverPatientApiDataSource(
      session: _FakeSession(),
      client: MockClient((_) async => http.Response('{"items":"bad"}', 200)),
    );
    await expectLater(
      source.fetchPatients(),
      throwsA(
        isA<CaregiverPatientApiFailure>().having(
          (e) => e.kind,
          'kind',
          CaregiverPatientFailureKind.malformed,
        ),
      ),
    );
  });

  test('patient detail returns typed 404', () async {
    final source = CaregiverPatientApiDataSource(
      session: _FakeSession(),
      client: MockClient((_) async => http.Response('', 404)),
    );
    await expectLater(
      source.fetchPatient('missing'),
      throwsA(
        isA<CaregiverPatientApiFailure>().having(
          (e) => e.kind,
          'kind',
          CaregiverPatientFailureKind.notFound,
        ),
      ),
    );
  });

  test('issues one 24-hour access code for the created patient', () async {
    final source = CaregiverPatientApiDataSource(
      session: _FakeSession(),
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/patients/patient-1/access-codes');
        expect(request.headers['authorization'], 'Bearer caregiver-token');
        expect(jsonDecode(request.body), {'expires_in_hours': 24});
        return http.Response(
          jsonEncode({
            'access_code_id': 'code-1',
            'patient_id': 'patient-1',
            'access_code': 'ONE-TIME',
            'created_by_user_id': 'caregiver-1',
            'created_at': '2026-09-06T10:00:00Z',
            'expires_at': '2026-09-07T10:00:00Z',
            'status': 'ACTIVE',
          }),
          201,
        );
      }),
    );

    final result = await source.createAccessCode('patient-1');
    expect(result.accessCode, 'ONE-TIME');
  });

  test('surfaces safe backend validation messages', () async {
    final source = CaregiverPatientApiDataSource(
      session: _FakeSession(),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'detail': [
              {
                'loc': ['body', 'full_name'],
                'msg': 'Name is invalid',
                'type': 'value_error',
              },
            ],
          }),
          422,
        ),
      ),
    );

    await expectLater(
      source.createPatient(const CreatePatientRequest(fullName: 'x')),
      throwsA(
        isA<CaregiverPatientApiFailure>().having(
          (e) => e.message,
          'message',
          'Name is invalid',
        ),
      ),
    );
  });

  test('401 clears the full session', () async {
    final session = _FakeSession();
    final source = CaregiverPatientApiDataSource(
      session: session,
      client: MockClient((_) async => http.Response('', 401)),
    );

    await expectLater(
      source.createPatient(const CreatePatientRequest(fullName: 'Ada')),
      throwsA(isA<CaregiverPatientApiFailure>()),
    );
    expect(session.cleared, isTrue);
  });
}

Map<String, dynamic> _patientJson({
  Object? heartRate = '72',
  Object? spo2 = '98',
}) => {
  'patient_id': 'patient-1',
  'user_id': 'user-1',
  'household_id': 'household-1',
  'account_status': 'ACTIVE',
  'assignment': null,
  'full_name': 'Ada',
  'birthdate': '1950-02-03',
  'sex': 'FEMALE',
  'phone_number': null,
  'address_or_room': null,
  'emergency_contact_name': null,
  'emergency_contact_phone': null,
  'known_conditions': null,
  'medications': null,
  'baseline_heart_rate': heartRate,
  'baseline_spo2': spo2,
  'monitoring_notes': null,
  'archived_at': null,
  'created_at': '2026-09-06T10:00:00Z',
};

Map<String, dynamic> _listPatientJson() => {
  'patient_id': 'patient-1',
  'user_id': 'user-1',
  'household_id': 'household-1',
  'full_name': 'Ada',
  'birthdate': null,
  'sex': null,
  'phone_number': null,
  'address_or_room': 'Room 4',
  'account_status': 'ACTIVE',
  'created_at': '2026-09-06T10:00:00Z',
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
};

class _FakeSession implements CaregiverSession {
  bool cleared = false;
  @override
  String? get accessToken => 'caregiver-token';
  @override
  String? get householdCode => 'HOME-123';
  @override
  Future<void> clearInvalidSession() async => cleared = true;
}
