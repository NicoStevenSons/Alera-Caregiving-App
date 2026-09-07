import 'package:flutter/foundation.dart';

import '../../domain/models/care_recipient.dart';
import '../../domain/models/health_snapshot.dart';
import '../api/caregiver_patient_api_data_source.dart';
import '../api/dto/patient_dto.dart';

enum CaregiverPatientListState {
  initialLoading,
  success,
  empty,
  error,
  demoFallback,
}

class CaregiverPatientController extends ChangeNotifier {
  final CaregiverPatientReadDataSource dataSource;
  final List<CareRecipient> demoPatients;
  CaregiverPatientListState state = CaregiverPatientListState.initialLoading;
  List<PatientListItemDto> patients = const [];
  String? errorMessage;
  CaregiverPatientFailureKind? failureKind;
  bool isRefreshing = false;

  CaregiverPatientController({
    required this.dataSource,
    this.demoPatients = const [],
  });

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      isRefreshing = true;
      notifyListeners();
    } else if (patients.isEmpty) {
      state = CaregiverPatientListState.initialLoading;
      notifyListeners();
    }
    try {
      final page = await dataSource.fetchPatients();
      patients = page.items;
      errorMessage = null;
      failureKind = null;
      state = patients.isEmpty
          ? CaregiverPatientListState.empty
          : CaregiverPatientListState.success;
    } on CaregiverPatientApiFailure catch (failure) {
      errorMessage = failure.message;
      failureKind = failure.kind;
      if ((failure.kind == CaregiverPatientFailureKind.connectivity ||
              failure.kind == CaregiverPatientFailureKind.server) &&
          demoPatients.isNotEmpty) {
        patients = const [];
        state = CaregiverPatientListState.demoFallback;
      } else {
        patients = const [];
        state = CaregiverPatientListState.error;
      }
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> refreshAfterCreate(String patientId) async {
    await load(refresh: true);
    // The backend list is authoritative; reconciliation is identity-based.
    if (state == CaregiverPatientListState.success) {
      final byId = <String, PatientListItemDto>{
        for (final patient in patients) patient.patientId: patient,
      };
      patients = List.unmodifiable(byId.values);
      notifyListeners();
    }
  }

  Future<PatientDetailDto> loadDetail(String patientId) =>
      dataSource.fetchPatient(patientId);

  List<CareRecipient> get visiblePatients =>
      state == CaregiverPatientListState.demoFallback
      ? demoPatients
      : patients.map(patientListItemToCareRecipient).toList(growable: false);
}

CareRecipient patientListItemToCareRecipient(PatientListItemDto patient) {
  final summary = patient.currentSummary;
  final status = switch (summary.monitoringStatus) {
    PatientMonitoringStatus.critical => CareStatus.critical,
    PatientMonitoringStatus.warning => CareStatus.warning,
    PatientMonitoringStatus.stable => CareStatus.stable,
    PatientMonitoringStatus.noData => CareStatus.noData,
    PatientMonitoringStatus.unknown => CareStatus.unknown,
  };
  final connectionLabel = switch (summary.deviceConnectionStatus) {
    PatientDeviceConnectionStatus.notConnected => 'Not connected',
    PatientDeviceConnectionStatus.connected => 'Connected',
    PatientDeviceConnectionStatus.syncing => 'Syncing',
    PatientDeviceConnectionStatus.failed => 'Connection failed',
    PatientDeviceConnectionStatus.disconnected => 'Disconnected',
    PatientDeviceConnectionStatus.unknown =>
      summary.deviceConnectionStatusValue,
  };
  return CareRecipient(
    id: patient.patientId,
    name: patient.fullName,
    relationshipLabel: 'Under your care',
    addressOrRoom: patient.addressOrRoom,
    monitoringStatusLabel: switch (summary.monitoringStatus) {
      PatientMonitoringStatus.noData => 'No data',
      PatientMonitoringStatus.unknown => summary.monitoringStatusValue,
      _ =>
        summary.monitoringStatusValue[0] +
            summary.monitoringStatusValue.substring(1).toLowerCase(),
    },
    backendBacked: true,
    status: status,
    alertCount: summary.activeAlertCount,
    reminderCount: 0,
    quickMessages: const [],
    healthSnapshot: HealthSnapshot(
      heartRateBpm: summary.latestHeartRate?.value.round(),
      heartRateUnit: summary.latestHeartRate?.unit,
      heartRateRecordedAt: summary.latestHeartRate?.recordedAt,
      spo2Percent: summary.latestSpo2?.value,
      spo2Unit: summary.latestSpo2?.unit,
      spo2RecordedAt: summary.latestSpo2?.recordedAt,
      steps: null,
      stressLabel: 'No data',
      sleepDuration: Duration.zero,
      careRiskScore: 0,
      careRiskLabel: 'Not assessed',
      lastCheckIn:
          summary.lastCheckIn ?? DateTime.fromMillisecondsSinceEpoch(0),
      hasLastCheckIn: summary.lastCheckIn != null,
      deviceConnectionLabel: connectionLabel,
      lastDeviceSyncAt: summary.lastDeviceSyncAt,
      highestActiveAlertSeverity: summary.highestActiveAlertSeverity,
      devices: const [],
    ),
  );
}

CareRecipient patientDetailToCareRecipient(PatientDetailDto patient) =>
    patientListItemToCareRecipient(patient);
