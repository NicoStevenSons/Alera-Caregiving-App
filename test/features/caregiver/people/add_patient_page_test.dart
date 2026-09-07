import 'dart:async';
import 'dart:convert';

import 'package:alera/features/caregiver/data/api/caregiver_patient_api_data_source.dart';
import 'package:alera/features/caregiver/data/api/dto/patient_dto.dart';
import 'package:alera/features/caregiver/presentation/people/add_patient_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('QR payload is valid JSON with the specified fields', () {
    expect(jsonDecode(buildPatientAccessQrPayload(accessCode: 'ONE-TIME')), {
      'type': 'alera_patient_access',
      'version': 2,
      'access_code': 'ONE-TIME',
    });
  });

  testWidgets('validates required and numeric fields', (tester) async {
    final source = _FakePatientSource();
    await _pump(tester, source);
    await _scrollToSubmit(tester);
    await tester.enterText(find.byKey(const Key('heart-rate-field')), '0');
    await tester.enterText(find.byKey(const Key('spo2-field')), '101');
    await tester.tap(find.text('Create Patient'));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byKey(const Key('patient-name-field')),
      -500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Enter the patient’s full name.'), findsOneWidget);
    await _scrollToSubmit(tester);
    expect(find.textContaining('greater than 0'), findsOneWidget);
    expect(find.textContaining('from 0 to 100'), findsOneWidget);
    expect(source.createCalls, 0);
  });

  testWidgets('loading disables duplicate patient submission', (tester) async {
    final completer = Completer<PatientCreatedResponse>();
    final source = _FakePatientSource(createCompleter: completer);
    await _pump(tester, source);
    await tester.enterText(find.byKey(const Key('patient-name-field')), 'Ada');
    await _scrollToSubmit(tester);
    await tester.tap(find.text('Create Patient'));
    await tester.pump();
    await tester.tap(find.text('Creating…'));
    expect(source.createCalls, 1);
    completer.complete(_created());
    await tester.pumpAndSettle();
    expect(find.text('Patient created'), findsOneWidget);
  });

  testWidgets('creation success remains successful when issuance fails', (
    tester,
  ) async {
    final source = _FakePatientSource(issueFailure: true);
    await _create(tester, source);
    await tester.tap(find.text('Generate Access Code'));
    await tester.pumpAndSettle();
    expect(find.text('Patient created'), findsOneWidget);
    expect(find.text('Unable to issue this code.'), findsOneWidget);
    expect(find.text('Generate Access Code'), findsOneWidget);
  });

  testWidgets('successful issuance displays code and QR only after request', (
    tester,
  ) async {
    final source = _FakePatientSource();
    await _create(tester, source);
    expect(find.byKey(const Key('issued-access-code')), findsNothing);
    await tester.tap(find.text('Generate Access Code'));
    await tester.pumpAndSettle();
    expect(find.text('ONE-TIME-CODE'), findsOneWidget);
    expect(find.text('HOME-123'), findsOneWidget);
    expect(find.byKey(const Key('access-code-qr')), findsOneWidget);
    expect(find.textContaining('usable only once'), findsOneWidget);
    expect(source.issueCalls, 1);
  });

  testWidgets('Done leaves the flow and plaintext code is not persisted', (
    tester,
  ) async {
    final source = _FakePatientSource();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AddPatientPage(
                  dataSource: source,
                  householdCode: 'HOME-123',
                  onPatientCreated: (_) {},
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('patient-name-field')), 'Ada');
    await _scrollToSubmit(tester);
    await tester.tap(find.text('Create Patient'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generate Access Code'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Done'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('ONE-TIME-CODE'), findsNothing);
  });

  testWidgets('Back leaves the patient form without creating a patient', (
    tester,
  ) async {
    final source = _FakePatientSource();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AddPatientPage(
                  dataSource: source,
                  householdCode: 'HOME-123',
                  onPatientCreated: (_) {},
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsOneWidget);
    expect(source.createCalls, 0);
  });
}

Future<void> _pump(WidgetTester tester, _FakePatientSource source) =>
    tester.pumpWidget(
      MaterialApp(
        home: AddPatientPage(
          dataSource: source,
          householdCode: 'HOME-123',
          onPatientCreated: (_) {},
        ),
      ),
    );

Future<void> _create(WidgetTester tester, _FakePatientSource source) async {
  await _pump(tester, source);
  await tester.enterText(find.byKey(const Key('patient-name-field')), 'Ada');
  await _scrollToSubmit(tester);
  await tester.tap(find.text('Create Patient'));
  await tester.pumpAndSettle();
}

Future<void> _scrollToSubmit(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Create Patient'),
    500,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

class _FakePatientSource implements CaregiverPatientDataSource {
  final Completer<PatientCreatedResponse>? createCompleter;
  final bool issueFailure;
  int createCalls = 0;
  int issueCalls = 0;
  _FakePatientSource({this.createCompleter, this.issueFailure = false});
  @override
  Future<PatientCreatedResponse> createPatient(CreatePatientRequest request) {
    createCalls++;
    return createCompleter?.future ?? Future.value(_created());
  }

  @override
  Future<PatientAccessCodeResponse> createAccessCode(String patientId) async {
    issueCalls++;
    if (issueFailure) {
      throw const CaregiverPatientApiFailure('Unable to issue this code.');
    }
    return PatientAccessCodeResponse(
      accessCodeId: 'code-1',
      patientId: patientId,
      accessCode: 'ONE-TIME-CODE',
      createdByUserId: 'caregiver-1',
      createdAt: DateTime.utc(2026, 9, 6),
      expiresAt: DateTime.utc(2026, 9, 7),
      status: 'ACTIVE',
    );
  }
}

PatientCreatedResponse _created() => PatientCreatedResponse(
  patientId: 'patient-1',
  userId: 'user-1',
  householdId: 'home-1',
  accountStatus: 'ACTIVE',
  assignment: null,
  fullName: 'Ada',
  birthdate: null,
  sex: null,
  phoneNumber: null,
  addressOrRoom: null,
  emergencyContactName: null,
  emergencyContactPhone: null,
  knownConditions: null,
  medications: null,
  baselineHeartRate: 72,
  baselineSpo2: 98,
  monitoringNotes: null,
  createdAt: DateTime.utc(2026, 9, 6),
);
