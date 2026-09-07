import 'package:alera/features/caregiver/data/api/caregiver_patient_api_data_source.dart';
import 'package:alera/features/caregiver/data/api/dto/patient_dto.dart';
import 'package:alera/features/caregiver/data/mock/mock_caregiver_repository.dart';
import 'package:alera/features/caregiver/data/patients/caregiver_patient_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'loading transitions to success and refresh reconciles patient_id',
    () async {
      final source = _ReadSource([_item('one'), _item('one')]);
      final controller = CaregiverPatientController(dataSource: source);
      expect(controller.state, CaregiverPatientListState.initialLoading);
      await controller.load();
      expect(controller.state, CaregiverPatientListState.success);
      await controller.refreshAfterCreate('one');
      expect(controller.patients, hasLength(1));
      expect(source.calls, 2);
    },
  );

  test('empty and retry states are explicit', () async {
    final source = _ReadSource(
      const [],
      failure: const CaregiverPatientApiFailure('down'),
    );
    final controller = CaregiverPatientController(dataSource: source);
    await controller.load();
    expect(controller.state, CaregiverPatientListState.error);
    source.failure = null;
    await controller.load();
    expect(controller.state, CaregiverPatientListState.empty);
  });

  test('network failure uses visibly distinct demo fallback', () async {
    final controller = CaregiverPatientController(
      dataSource: _ReadSource(
        const [],
        failure: const CaregiverPatientApiFailure(
          'offline',
          kind: CaregiverPatientFailureKind.connectivity,
        ),
      ),
      demoPatients: const MockCaregiverRepository().getCareRecipients(),
    );
    await controller.load();
    expect(controller.state, CaregiverPatientListState.demoFallback);
    expect(controller.visiblePatients, isNotEmpty);
  });

  test('403 and malformed failures never use demo fallback', () async {
    for (final kind in [
      CaregiverPatientFailureKind.forbidden,
      CaregiverPatientFailureKind.malformed,
    ]) {
      final controller = CaregiverPatientController(
        dataSource: _ReadSource(
          const [],
          failure: CaregiverPatientApiFailure('bad', kind: kind),
        ),
        demoPatients: const MockCaregiverRepository().getCareRecipients(),
      );
      await controller.load();
      expect(controller.state, CaregiverPatientListState.error);
      expect(controller.visiblePatients, isEmpty);
    }
  });
}

class _ReadSource implements CaregiverPatientReadDataSource {
  final List<PatientListItemDto> items;
  CaregiverPatientApiFailure? failure;
  int calls = 0;
  _ReadSource(this.items, {this.failure});
  @override
  Future<PaginatedPatientListDto> fetchPatients({
    int limit = 100,
    int offset = 0,
  }) async {
    calls++;
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

PatientListItemDto _item(String id) => PatientListItemDto(
  patientId: id,
  userId: 'u',
  householdId: 'h',
  fullName: 'Ada',
  birthdate: null,
  sex: null,
  phoneNumber: null,
  addressOrRoom: 'Room 4',
  accountStatus: 'ACTIVE',
  createdAt: DateTime.utc(2026),
  currentSummary: CurrentHealthSummaryDto(
    latestHeartRate: null,
    latestSpo2: null,
    lastCheckIn: null,
    activeAlertCount: 0,
    highestActiveAlertSeverity: null,
    monitoringStatus: PatientMonitoringStatus.noData,
    monitoringStatusValue: 'NO_DATA',
    deviceConnectionStatus: PatientDeviceConnectionStatus.notConnected,
    deviceConnectionStatusValue: 'NOT_CONNECTED',
    lastDeviceSyncAt: null,
  ),
);
