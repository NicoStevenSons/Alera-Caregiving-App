import 'package:alera/features/caregiver/caregiver_shell.dart';
import 'package:alera/features/caregiver/data/api/caregiver_patient_api_data_source.dart';
import 'package:alera/features/caregiver/data/api/dto/patient_dto.dart';
import 'package:alera/features/caregiver/data/mock/mock_caregiver_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('newly created patient appears in People after Done', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CaregiverShell(
          repository: const MockCaregiverRepository(),
          patientDataSource: _CreateOnlySource(),
          householdCode: 'HOME-123',
        ),
      ),
    );

    await tester.tap(find.text('People').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Patient'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('patient-name-field')),
      'New Patient',
    );
    await tester.scrollUntilVisible(
      find.text('Create Patient'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Create Patient'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('New Patient'), findsOneWidget);
  });
}

class _CreateOnlySource implements CaregiverPatientDataSource {
  @override
  Future<PatientCreatedResponse> createPatient(
    CreatePatientRequest request,
  ) async => PatientCreatedResponse(
    patientId: 'new-patient',
    userId: 'new-user',
    householdId: 'home',
    accountStatus: 'ACTIVE',
    assignment: null,
    fullName: request.fullName,
    birthdate: null,
    sex: null,
    phoneNumber: null,
    addressOrRoom: null,
    emergencyContactName: null,
    emergencyContactPhone: null,
    knownConditions: null,
    medications: null,
    baselineHeartRate: null,
    baselineSpo2: null,
    monitoringNotes: null,
    createdAt: DateTime.utc(2026, 9, 6),
  );

  @override
  Future<PatientAccessCodeResponse> createAccessCode(String patientId) =>
      throw UnimplementedError();
}
