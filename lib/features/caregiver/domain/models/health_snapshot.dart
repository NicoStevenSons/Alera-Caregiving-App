enum MonitoringDeviceConnectionStatus { connected, disconnected, unknown }

class MonitoringDevice {
  final String name;
  final int? batteryPercent;
  final MonitoringDeviceConnectionStatus connectionStatus;
  final bool? isWorn;
  final DateTime? notWornSince;

  const MonitoringDevice({
    required this.name,
    required this.batteryPercent,
    required this.connectionStatus,
    this.isWorn,
    this.notWornSince,
  });

  bool get isConnected =>
      connectionStatus == MonitoringDeviceConnectionStatus.connected;
}

extension MonitoringDeviceListLookup on List<MonitoringDevice> {
  MonitoringDevice? get watch => _findByName('watch');

  MonitoringDevice? get phone => _findByName('phone');

  MonitoringDevice? _findByName(String expectedName) {
    for (final device in this) {
      if (device.name.toLowerCase() == expectedName) {
        return device;
      }
    }

    return null;
  }
}

class HealthSnapshot {
  final int? heartRateBpm;
  final String? heartRateUnit;
  final DateTime? heartRateRecordedAt;
  final double? spo2Percent;
  final String? spo2Unit;
  final DateTime? spo2RecordedAt;

  final int? steps;
  final DateTime? stepsUpdatedAt;
  final String stressLabel;
  final Duration sleepDuration;
  final DateTime? sleepDate;

  final int careRiskScore;
  final String careRiskLabel;
  final DateTime lastCheckIn;
  final bool hasLastCheckIn;
  final String? deviceConnectionLabel;
  final DateTime? lastDeviceSyncAt;
  final String? highestActiveAlertSeverity;
  final List<MonitoringDevice> devices;

  const HealthSnapshot({
    required this.heartRateBpm,
    this.heartRateUnit,
    this.heartRateRecordedAt,
    required this.spo2Percent,
    this.spo2Unit,
    this.spo2RecordedAt,

    required this.steps,
    this.stepsUpdatedAt,
    required this.stressLabel,
    required this.sleepDuration,
    this.sleepDate,

    required this.careRiskScore,
    required this.careRiskLabel,
    required this.lastCheckIn,
    this.hasLastCheckIn = true,
    this.deviceConnectionLabel,
    this.lastDeviceSyncAt,
    this.highestActiveAlertSeverity,
    required this.devices,
  });
}
