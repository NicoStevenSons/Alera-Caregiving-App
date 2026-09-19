import 'package:alera/features/caregiver/data/api/caregiver_patient_api_data_source.dart';
import 'package:alera/features/caregiver/data/api/dto/patient_dto.dart';
import 'package:alera/features/caregiver/presentation/people/patient_access_setup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('connected patient can generate a new login code', (
    tester,
  ) async {
    final source = _AccessSource();
    await tester.pumpWidget(
      MaterialApp(
        home: PatientAccessSetupPage(
          patientId: 'patient-1',
          patientName: 'Maria',
          patientAccess: PatientAccessStatus(
            status: PatientAccessState.notConnected,
            statusValue: 'NOT_CONNECTED',
            pendingAccessCodeId: null,
            pendingExpiresAt: null,
            connectedAt: DateTime.utc(2026, 9, 1),
          ),
          dataSource: source,
          loadPatientDetail: (_) => throw Exception('poll unavailable'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    final buttonFinder = find.text('Generate access code');
    await tester.ensureVisible(buttonFinder);
    expect(buttonFinder, findsOneWidget);
    await tester.tap(buttonFinder);
    await tester.pump();
    await tester.pump();

    expect(source.issueCalls, 1);
    expect(find.byKey(const Key('issued-access-code')), findsOneWidget);
    expect(find.text('RELOGIN-CODE'), findsOneWidget);
    expect(find.byKey(const Key('access-code-qr')), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
  });
}

class _AccessSource implements CaregiverPatientDataSource {
  int issueCalls = 0;

  @override
  Future<PatientAccessCodeResponse> createAccessCode(String patientId) async {
    issueCalls++;
    return PatientAccessCodeResponse(
      accessCodeId: 'code-2',
      patientId: patientId,
      accessCode: 'RELOGIN-CODE',
      createdByUserId: 'caregiver-1',
      createdAt: DateTime.utc(2026, 9, 19),
      expiresAt: DateTime.utc(2026, 9, 20),
      status: 'ACTIVE',
    );
  }

  @override
  Future<PatientCreatedResponse> createPatient(CreatePatientRequest request) =>
      throw UnimplementedError();

  @override
  Future<MonitoringSettingsResponse> updateMonitoringSettings(
    String patientId,
    UpdateMonitoringSettingsRequest request,
  ) => throw UnimplementedError();
}
