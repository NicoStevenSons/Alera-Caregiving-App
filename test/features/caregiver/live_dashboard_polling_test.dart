import 'package:alera/features/caregiver/caregiver_shell.dart';
import 'package:alera/features/caregiver/data/api/caregiver_patient_api_data_source.dart';
import 'package:alera/features/caregiver/data/api/dto/monitoring_device_dto.dart';
import 'package:alera/features/caregiver/data/api/dto/patient_dto.dart';
import 'package:alera/features/caregiver/data/mock/mock_caregiver_repository.dart';
import 'package:alera/features/caregiver/data/patients/caregiver_patient_controller.dart';
import 'package:alera/features/caregiver/domain/models/care_recipient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home polls patients while visible and pauses off Home', (
    WidgetTester tester,
  ) async {
    final source = _SequencePatientSource([
      PatientMonitoringStatus.critical,
      PatientMonitoringStatus.warning,
      PatientMonitoringStatus.stable,
    ]);
    final controller = CaregiverPatientController(dataSource: source);
    await controller.load();

    expect(source.fetchCount, 1);
    expect(controller.visiblePatients.single.status, CareStatus.critical);

    await tester.pumpWidget(
      MaterialApp(
        home: CaregiverShell(
          repository: const MockCaregiverRepository(),
          patientController: controller,
          patientPollingInterval: const Duration(seconds: 1),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(source.fetchCount, 2);
    expect(controller.visiblePatients.single.status, CareStatus.warning);

    await tester.tap(find.text('People'));
    await tester.pump();
    final countAfterLeavingHome = source.fetchCount;

    await tester.pump(const Duration(seconds: 3));
    expect(source.fetchCount, countAfterLeavingHome);

    await tester.tap(find.text('Home'));
    await tester.pump();
    await tester.pump();
    expect(source.fetchCount, countAfterLeavingHome + 1);
    expect(controller.visiblePatients.single.status, CareStatus.stable);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  test(
    'transient refresh keeps the last successful patient snapshot',
    () async {
      final source = _SequencePatientSource([PatientMonitoringStatus.stable]);
      final controller = CaregiverPatientController(dataSource: source);
      await controller.load();

      source.failWithConnectivity = true;
      await controller.load(refresh: true);

      expect(controller.state, CaregiverPatientListState.success);
      expect(controller.patients, hasLength(1));
      expect(controller.visiblePatients.single.status, CareStatus.stable);

      controller.dispose();
    },
  );
}

class _SequencePatientSource implements CaregiverPatientReadDataSource {
  final List<PatientMonitoringStatus> statuses;
  int fetchCount = 0;
  bool failWithConnectivity = false;

  _SequencePatientSource(this.statuses);

  @override
  Future<PaginatedPatientListDto> fetchPatients({
    int limit = 100,
    int offset = 0,
  }) async {
    if (failWithConnectivity) {
      throw const CaregiverPatientApiFailure(
        'offline',
        kind: CaregiverPatientFailureKind.connectivity,
      );
    }

    final index = fetchCount < statuses.length
        ? fetchCount
        : statuses.length - 1;
    final status = statuses[index];
    fetchCount += 1;

    return PaginatedPatientListDto(
      items: [_patient(status)],
      total: 1,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<PatientDetailDto> fetchPatient(String patientId) =>
      throw UnimplementedError();

  @override
  Future<List<MonitoringDeviceDto>> fetchMonitoringDevices(
    String patientId,
  ) async {
    return const <MonitoringDeviceDto>[];
  }
}

PatientListItemDto _patient(PatientMonitoringStatus status) {
  final statusValue = switch (status) {
    PatientMonitoringStatus.critical => 'CRITICAL',
    PatientMonitoringStatus.warning => 'WARNING',
    PatientMonitoringStatus.stable => 'STABLE',
    PatientMonitoringStatus.noData => 'NO_DATA',
    PatientMonitoringStatus.unknown => 'UNKNOWN',
  };
  final heartRate = switch (status) {
    PatientMonitoringStatus.critical => 160.0,
    PatientMonitoringStatus.warning => 120.0,
    PatientMonitoringStatus.stable => 78.0,
    _ => 78.0,
  };

  return PatientListItemDto(
    patientId: 'patient-1',
    userId: 'user-1',
    householdId: 'household-1',
    fullName: 'Polling Patient',
    birthdate: null,
    sex: null,
    phoneNumber: null,
    addressOrRoom: 'Room 1',
    accountStatus: 'ACTIVE',
    createdAt: DateTime.utc(2026, 9, 19),
    currentSummary: CurrentHealthSummaryDto(
      latestHeartRate: LatestMetricReadingDto(
        value: heartRate,
        unit: 'bpm',
        recordedAt: DateTime.utc(2026, 9, 19, 8),
      ),
      latestSpo2: null,
      lastCheckIn: DateTime.utc(2026, 9, 19, 8),
      activeAlertCount: status == PatientMonitoringStatus.critical ? 1 : 0,
      highestActiveAlertSeverity: status == PatientMonitoringStatus.critical
          ? 'CRITICAL'
          : null,
      monitoringStatus: status,
      monitoringStatusValue: statusValue,
      deviceConnectionStatus: PatientDeviceConnectionStatus.connected,
      deviceConnectionStatusValue: 'CONNECTED',

      todaySteps: null,
      stepsUpdatedAt: null,
      latestSleepDurationSeconds: null,
      latestSleepDate: null,
      lastDeviceSyncAt: DateTime.utc(2026, 9, 19, 8),
    ),
  );
}
