import 'package:alera/features/caregiver/data/api/caregiver_patient_api_data_source.dart';
import 'package:alera/features/caregiver/data/api/dto/monitoring_device_dto.dart';
import 'package:alera/features/caregiver/data/api/dto/patient_dto.dart';
import 'package:alera/features/caregiver/data/patients/caregiver_patient_controller.dart';
import 'package:alera/features/caregiver/domain/models/care_recipient.dart';
import 'package:alera/features/caregiver/domain/models/health_snapshot.dart';
import 'package:alera/features/caregiver/presentation/patient_detail/caregiver_patient_detail_page.dart';
import 'package:alera/features/caregiver/presentation/people/widgets/care_recipient_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../people/edit_patient_test_support.dart';

class _ReadSource implements CaregiverPatientReadDataSource {
  PatientDetailDto detail = editPatient();

  @override
  Future<PatientDetailDto> fetchPatient(String patientId) async => detail;

  @override
  Future<List<MonitoringDeviceDto>> fetchMonitoringDevices(
    String patientId,
  ) async => const [];

  @override
  Future<PaginatedPatientListDto> fetchPatients({
    int limit = 100,
    int offset = 0,
  }) async => PaginatedPatientListDto(
    items: [PatientListItemDto.fromJson(editPatientJson())],
    total: 1,
    limit: limit,
    offset: offset,
  );
}

final HealthSnapshot _snapshot = HealthSnapshot(
  heartRateBpm: null,
  spo2Percent: null,
  steps: null,
  stressLabel: 'No data',
  sleepDuration: Duration.zero,
  careRiskScore: 0,
  careRiskLabel: 'Not assessed',
  lastCheckIn: DateTime(2026, 9, 3),
  devices: const [],
);

void main() {
  testWidgets('edit from patient detail updates detail and People state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final read = _ReadSource();
    final controller = CaregiverPatientController(dataSource: read);
    addTearDown(controller.dispose);
    await controller.load();
    final edit = FakePatientEditDataSource();

    await tester.pumpWidget(
      MaterialApp(
        home: CaregiverPatientDetailLoaderPage(
          patientId: 'patient-1',
          controller: controller,
          patientDataSource: FakePhotoDataSource(),
          patientEditDataSource: edit,
          alerts: const [],
          reminders: const [],
          onViewAllAlerts: () {},
          onViewAllReminders: () {},
          onAlertTap: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // No label yet, so the fallback text is shown.
    expect(find.text('Under your care'), findsWidgets);
    expect(controller.visiblePatients.single.relationship, isNull);

    await tester.tap(find.byKey(const Key('edit-patient-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('relationship-suggestion-Mother')));
    await tester.enterText(
      find.byKey(const Key('edit-name-field')),
      'Maria S.',
    );
    await tester.tap(find.byKey(const Key('edit-patient-save')));
    await tester.pumpAndSettle();

    expect(edit.requests.single.relationshipLabel, 'Mother');
    // Detail page now shows the saved values and a confirmation.
    expect(find.text('Mother'), findsOneWidget);
    expect(find.text('Maria S.'), findsWidgets);
    expect(find.text('Patient updated.'), findsOneWidget);
    // The People list state changed without waiting for a refresh.
    expect(controller.patients.single.fullName, 'Maria S.');
    expect(controller.visiblePatients.single.relationship, 'Mother');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a failed save leaves the detail page unchanged', (tester) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = CaregiverPatientController(dataSource: _ReadSource());
    addTearDown(controller.dispose);
    await controller.load();
    final edit = FakePatientEditDataSource()
      ..failure = const CaregiverPatientApiFailure('Server is busy.');

    await tester.pumpWidget(
      MaterialApp(
        home: CaregiverPatientDetailLoaderPage(
          patientId: 'patient-1',
          controller: controller,
          patientDataSource: FakePhotoDataSource(),
          patientEditDataSource: edit,
          alerts: const [],
          reminders: const [],
          onViewAllAlerts: () {},
          onViewAllReminders: () {},
          onAlertTap: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-patient-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('edit-name-field')), 'Changed');
    await tester.tap(find.byKey(const Key('edit-patient-save')));
    await tester.pumpAndSettle();

    expect(find.text('Server is busy.'), findsOneWidget);
    expect(controller.patients.single.fullName, 'Maria Santos');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('People card shows the relationship under the name', (
    tester,
  ) async {
    CareRecipient recipient({String? relationship}) => CareRecipient(
      id: 'p1',
      name: 'Maria Santos',
      relationshipLabel: 'Under your care',
      relationship: relationship,
      status: CareStatus.stable,
      alertCount: 0,
      reminderCount: 0,
      quickMessages: const [],
      healthSnapshot: _snapshot,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CareRecipientCard(
            careRecipient: recipient(relationship: 'Grandmother'),
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('person-relationship-p1')), findsOneWidget);
    expect(find.text('Grandmother'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CareRecipientCard(careRecipient: recipient(), onTap: () {}),
        ),
      ),
    );
    expect(find.byKey(const Key('person-relationship-p1')), findsNothing);
  });
}
