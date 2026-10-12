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
    await pickRelationship(tester, 'Mother');
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

  testWidgets('archiving from Edit removes the patient and leaves detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = CaregiverPatientController(dataSource: _ReadSource());
    addTearDown(controller.dispose);
    await controller.load();
    final archive = FakeArchiveDataSource();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              key: const Key('open-detail'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CaregiverPatientDetailLoaderPage(
                    patientId: 'patient-1',
                    controller: controller,
                    patientDataSource: FakePhotoDataSource(),
                    patientEditDataSource: FakePatientEditDataSource(),
                    patientArchiveDataSource: archive,
                    alerts: const [],
                    reminders: const [],
                    onViewAllAlerts: () {},
                    onViewAllReminders: () {},
                    onAlertTap: (_) {},
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-detail')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-patient-button')));
    await tester.pumpAndSettle();

    final archiveButton = find.byKey(const Key('edit-archive-patient'));
    await tester.ensureVisible(archiveButton);
    await tester.tap(archiveButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(archive.archived, ['patient-1']);
    expect(controller.patients, isEmpty);
    // Back on the page that opened the detail, with a confirmation.
    expect(find.byKey(const Key('open-detail')), findsOneWidget);
    expect(find.byKey(const Key('edit-patient-button')), findsNothing);
    expect(find.text('Maria Santos archived.'), findsOneWidget);
  });

  testWidgets('ranges saved then Edit cancelled still update the detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final read = _ReadSource();
    final controller = CaregiverPatientController(dataSource: read);
    addTearDown(controller.dispose);
    await controller.load();
    final photos = FakePhotoDataSource();

    await tester.pumpWidget(
      MaterialApp(
        home: CaregiverPatientDetailLoaderPage(
          patientId: 'patient-1',
          controller: controller,
          patientDataSource: photos,
          patientEditDataSource: FakePatientEditDataSource(),
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

    final row = find.byKey(const Key('edit-monitoring-ranges'));
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('monitoring-custom-option')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('monitoring-hr-min-field')),
      '50',
    );
    await tester.tap(find.byKey(const Key('edit-monitoring-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(photos.monitoringRequests.single.normalHrMin, 50);
    expect(find.byKey(const Key('edit-patient-form')), findsNothing);
    expect(find.text('Patient updated.'), findsOneWidget);

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
