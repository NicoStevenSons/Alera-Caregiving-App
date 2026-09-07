import 'package:alera/features/caregiver/caregiver_shell.dart';
import 'package:alera/features/caregiver/data/mock/mock_caregiver_repository.dart';
import 'package:alera/features/caregiver/data/api/caregiver_patient_api_data_source.dart';
import 'package:alera/features/caregiver/data/api/dto/patient_dto.dart';
import 'package:alera/features/caregiver/data/patients/caregiver_patient_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders real Home dashboard and fixed shell navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CaregiverShell(repository: MockCaregiverRepository()),
      ),
    );

    expect(find.text('Maria Santos'), findsOneWidget);
    expect(find.text('Needs Attention'), findsOneWidget);
    expect(find.text('Low Stress'), findsOneWidget);
    expect(find.text('Alerts (1 active)'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text("Today's Insights"),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text("Today's Insights"), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('View all Reminders'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('View all Reminders'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('Home actions are mock-only and links switch shell tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CaregiverShell(repository: MockCaregiverRepository()),
      ),
    );

    await tester.tap(find.text('Call').first);
    await tester.pump();
    expect(find.text('Call is mock-only for now.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('View All Alerts'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('View All Alerts'));
    await tester.pumpAndSettle();

    final NavigationBar navigationBar = tester.widget(
      find.byType(NavigationBar),
    );
    expect(navigationBar.selectedIndex, 2);
  });

  testWidgets('shared controller drives loading then real patient health', (
    tester,
  ) async {
    final source = _HomePatientSource([_patient('Backend Ada')]);
    final controller = CaregiverPatientController(dataSource: source);
    await _pumpControlledHome(tester, controller);
    expect(find.byKey(const Key('home-patient-loading')), findsOneWidget);

    await controller.load();
    await tester.pump();
    expect(find.text('Backend Ada'), findsOneWidget);
    expect(find.text('Warning'), findsOneWidget);
    expect(
      find.text('One or more readings need a closer look.'),
      findsOneWidget,
    );
    expect(find.textContaining('81 bpm'), findsOneWidget);
    expect(find.textContaining('97%'), findsOneWidget);
    expect(find.textContaining('Highest severity:'), findsNothing);
    expect(find.textContaining('Device:'), findsNothing);
    expect(find.text('Love you ❤️'), findsOneWidget);
    expect(find.text('Stress — mock-only'), findsOneWidget);
    expect(source.listCalls, 1);
  });

  testWidgets('empty assigned patient state is explicit', (tester) async {
    final controller = CaregiverPatientController(
      dataSource: _HomePatientSource(const []),
    );
    await controller.load();
    await _pumpControlledHome(tester, controller);
    expect(find.byKey(const Key('home-patient-empty')), findsOneWidget);
  });

  testWidgets('retryable failure retries through shared controller', (
    tester,
  ) async {
    final source = _HomePatientSource([
      _patient('Recovered Patient'),
    ], failure: const CaregiverPatientApiFailure('Temporary failure'));
    final controller = CaregiverPatientController(dataSource: source);
    await controller.load();
    await _pumpControlledHome(tester, controller);
    expect(find.byKey(const Key('home-patient-error')), findsOneWidget);
    source.failure = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Recovered Patient'), findsOneWidget);
    expect(source.listCalls, 2);
  });

  testWidgets('forbidden response has no fallback or retry', (tester) async {
    final controller = CaregiverPatientController(
      dataSource: _HomePatientSource(
        const [],
        failure: const CaregiverPatientApiFailure(
          'You do not have permission to view patients.',
          kind: CaregiverPatientFailureKind.forbidden,
        ),
      ),
      demoPatients: const MockCaregiverRepository().getCareRecipients(),
    );
    await controller.load();
    await _pumpControlledHome(tester, controller);
    expect(find.byKey(const Key('home-patient-forbidden')), findsOneWidget);
    expect(find.byKey(const Key('home-demo-fallback')), findsNothing);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('connectivity failure labels demo fallback', (tester) async {
    final controller = CaregiverPatientController(
      dataSource: _HomePatientSource(
        const [],
        failure: const CaregiverPatientApiFailure(
          'Offline',
          kind: CaregiverPatientFailureKind.connectivity,
        ),
      ),
      demoPatients: const MockCaregiverRepository().getCareRecipients(),
    );
    await controller.load();
    await _pumpControlledHome(tester, controller);
    expect(find.byKey(const Key('home-demo-fallback')), findsOneWidget);
    expect(find.text('Maria Santos'), findsOneWidget);
  });

  testWidgets('shared refresh updates Home without a Home-owned request', (
    tester,
  ) async {
    final source = _HomePatientSource([_patient('First Patient')]);
    final controller = CaregiverPatientController(dataSource: source);
    await controller.load();
    await _pumpControlledHome(tester, controller);
    expect(source.listCalls, 1);
    expect(find.text('First Patient'), findsOneWidget);

    source.items = [_patient('Updated Patient')];
    await controller.load(refresh: true);
    await tester.pump();
    expect(find.text('Updated Patient'), findsOneWidget);
    expect(source.listCalls, 2);
  });
}

Future<void> _pumpControlledHome(
  WidgetTester tester,
  CaregiverPatientController controller,
) => tester.pumpWidget(
  MaterialApp(
    home: CaregiverShell(
      repository: const MockCaregiverRepository(),
      patientController: controller,
    ),
  ),
);

class _HomePatientSource implements CaregiverPatientReadDataSource {
  List<PatientListItemDto> items;
  CaregiverPatientApiFailure? failure;
  int listCalls = 0;

  _HomePatientSource(this.items, {this.failure});

  @override
  Future<PaginatedPatientListDto> fetchPatients({
    int limit = 100,
    int offset = 0,
  }) async {
    listCalls++;
    if (failure != null) throw failure!;
    return PaginatedPatientListDto(
      items: items,
      total: items.length,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<PatientDetailDto> fetchPatient(String patientId) =>
      throw UnimplementedError();
}

PatientListItemDto _patient(String name) => PatientListItemDto(
  patientId: name,
  userId: 'user',
  householdId: 'household',
  fullName: name,
  birthdate: null,
  sex: null,
  phoneNumber: null,
  addressOrRoom: 'Room 8',
  accountStatus: 'ACTIVE',
  createdAt: DateTime.utc(2026, 9, 6),
  currentSummary: CurrentHealthSummaryDto(
    latestHeartRate: LatestMetricReadingDto(
      value: 81,
      unit: 'bpm',
      recordedAt: DateTime.utc(2026, 9, 6, 10, 1),
    ),
    latestSpo2: LatestMetricReadingDto(
      value: 97,
      unit: '%',
      recordedAt: DateTime.utc(2026, 9, 6, 10, 2),
    ),
    lastCheckIn: DateTime.utc(2026, 9, 6, 10, 2),
    activeAlertCount: 2,
    highestActiveAlertSeverity: 'WARNING',
    monitoringStatus: PatientMonitoringStatus.warning,
    monitoringStatusValue: 'WARNING',
    deviceConnectionStatus: PatientDeviceConnectionStatus.connected,
    deviceConnectionStatusValue: 'CONNECTED',
    lastDeviceSyncAt: DateTime.utc(2026, 9, 6, 10),
  ),
);
