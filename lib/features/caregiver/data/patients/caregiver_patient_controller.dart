import 'package:flutter/foundation.dart';

import '../../domain/models/care_recipient.dart';
import '../../domain/models/health_snapshot.dart';
import '../api/caregiver_patient_api_data_source.dart';
import '../api/dto/patient_dto.dart';
import '../api/dto/monitoring_device_dto.dart';

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
  int _loadRevision = 0;

  final Map<String, List<MonitoringDeviceDto>>
    _monitoringDevicesByPatient = {};

  CaregiverPatientController({
    required this.dataSource,
    this.demoPatients = const [],
  });

  Future<void> load({bool refresh = false}) async {
    final hadPatients = patients.isNotEmpty;
    final revision = ++_loadRevision;
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

final List<MapEntry<String, List<MonitoringDeviceDto>>> deviceEntries =
    await Future.wait<MapEntry<String, List<MonitoringDeviceDto>>>(
      patients.map<Future<MapEntry<String, List<MonitoringDeviceDto>>>>(
        (patient) async {
          try {
            final devices = await dataSource.fetchMonitoringDevices(
              patient.patientId,
            );

            return MapEntry<String, List<MonitoringDeviceDto>>(
              patient.patientId,
              devices,
            );
          } on CaregiverPatientApiFailure catch (failure) {
            if (failure.kind ==
                    CaregiverPatientFailureKind.unauthorized ||
                failure.kind ==
                    CaregiverPatientFailureKind.forbidden) {
              rethrow;
            }

            return MapEntry<String, List<MonitoringDeviceDto>>(
              patient.patientId,
              const <MonitoringDeviceDto>[],
            );
          }
        },
      ),
    );
    
  _monitoringDevicesByPatient
    ..clear()
    ..addEntries(deviceEntries);

  errorMessage = null;
  failureKind = null;

  state = patients.isEmpty
    ? CaregiverPatientListState.empty
    : CaregiverPatientListState.success;
    } on CaregiverPatientApiFailure catch (failure) {
      if (revision != _loadRevision) return;
      errorMessage = failure.message;
      failureKind = failure.kind;
      final transientFailure =
          failure.kind == CaregiverPatientFailureKind.connectivity ||
          failure.kind == CaregiverPatientFailureKind.server;
      if (refresh && hadPatients && transientFailure) {
        // Background/periodic refreshes keep the last known-good dashboard
        // instead of replacing it with demo/error data after one timeout.
        state = CaregiverPatientListState.success;
      } else if (transientFailure && demoPatients.isNotEmpty) {
        patients = const [];
        state = CaregiverPatientListState.demoFallback;
      } else {
        patients = const [];
        state = CaregiverPatientListState.error;
      }
    } finally {
      if (revision == _loadRevision) {
        isRefreshing = false;
        notifyListeners();
      }
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

  Future<List<MonitoringDeviceDto>> loadMonitoringDevices(String patientId) =>
      dataSource.fetchMonitoringDevices(patientId);

  List<CareRecipient> get visiblePatients {
  if (state == CaregiverPatientListState.demoFallback) {
    return demoPatients;
  }

  return patients.map((patient) {
    final deviceDtos =
        _monitoringDevicesByPatient[patient.patientId] ??
        const <MonitoringDeviceDto>[];

      final devices = deviceDtos
          .map(monitoringDeviceDtoToDomain)
          .toList(growable: false);

      return patientListItemToCareRecipient(
        patient,
        devices: devices,
      );
    }).toList(growable: false);
  }
}

CareRecipient patientListItemToCareRecipient(
  PatientListItemDto patient, {
  List<MonitoringDevice> devices = const [],
}) {
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
    phoneNumber: patient.phoneNumber,
    profilePhotoUrl: patient.profilePhotoUrl,
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

      steps: summary.todaySteps,
      stepsUpdatedAt: summary.stepsUpdatedAt,

      stressLabel: 'No data',

      sleepDuration: Duration(
        seconds: summary.latestSleepDurationSeconds ?? 0,
      ),
      sleepDate: summary.latestSleepDate,

      careRiskScore: 0,
      careRiskLabel: 'Not assessed',
      lastCheckIn:
          summary.lastCheckIn ?? DateTime.fromMillisecondsSinceEpoch(0),
      hasLastCheckIn: summary.lastCheckIn != null,
      deviceConnectionLabel: connectionLabel,
      lastDeviceSyncAt: summary.lastDeviceSyncAt,
      highestActiveAlertSeverity: summary.highestActiveAlertSeverity,
      devices: devices,
    ),
  );
}

CareRecipient patientDetailToCareRecipient(
  PatientDetailDto patient, {
  List<MonitoringDeviceDto> monitoringDevices = const [],
}) {
  return patientListItemToCareRecipient(
    patient,
    devices: monitoringDevices
        .map(monitoringDeviceDtoToDomain)
        .toList(growable: false),
  );
}

MonitoringDevice monitoringDeviceDtoToDomain(MonitoringDeviceDto device) {
  final name = switch (device.deviceType) {
    MonitoringDeviceTypeDto.watch => 'Watch',
    MonitoringDeviceTypeDto.phone => 'Phone',
    MonitoringDeviceTypeDto.unknown =>
      device.deviceName ?? device.deviceTypeValue,
  };

  final connectionStatus = switch (device.connectionStatus) {
    DeviceConnectionStatusDto.connected =>
      MonitoringDeviceConnectionStatus.connected,
    DeviceConnectionStatusDto.disconnected =>
      MonitoringDeviceConnectionStatus.disconnected,
    DeviceConnectionStatusDto.unknown =>
      MonitoringDeviceConnectionStatus.unknown,
  };

  return MonitoringDevice(
    name: name,
    batteryPercent: device.batteryPercent,
    connectionStatus: connectionStatus,
    isWorn: device.isWorn,
    notWornSince: device.notWornSince,
  );
}
