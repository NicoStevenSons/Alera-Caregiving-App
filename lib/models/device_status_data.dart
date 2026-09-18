class DeviceStatusData {
  final int? batteryPercent;
  final String? deviceName;
  final String? deviceModel;
  final bool? connectedToPhone;
  final String? connectedPhoneName;
  final bool? isCharging;
  final String? measuredAt;

  const DeviceStatusData({
    required this.batteryPercent,
    required this.deviceName,
    required this.deviceModel,
    required this.connectedToPhone,
    required this.connectedPhoneName,
    required this.isCharging,
    required this.measuredAt,
  });

  factory DeviceStatusData.fromJson(Map<String, dynamic> json) {
    final num? batteryValue = json['battery_percent'] as num?;
    final dynamic chargingValue = json['is_charging'] ?? json['charging'];

    bool? parsedCharging;
    if (chargingValue is bool) {
      parsedCharging = chargingValue;
    } else if (chargingValue is num) {
      parsedCharging = chargingValue != 0;
    } else if (chargingValue is String) {
      final String normalized = chargingValue.trim().toLowerCase();
      if (normalized == 'true' || normalized == 'charging' || normalized == '1') {
        parsedCharging = true;
      } else if (normalized == 'false' ||
          normalized == 'not_charging' ||
          normalized == '0') {
        parsedCharging = false;
      }
    }

    return DeviceStatusData(
      batteryPercent: batteryValue?.toInt(),
      deviceName: json['device_name'] as String?,
      deviceModel: json['device_model'] as String?,
      connectedToPhone: json['connected_to_phone'] as bool?,
      connectedPhoneName: json['connected_phone_name'] as String?,
      isCharging: parsedCharging,
      measuredAt: json['measured_at'] as String?,
    );
  }

  factory DeviceStatusData.empty() {
    return const DeviceStatusData(
      batteryPercent: null,
      deviceName: null,
      deviceModel: null,
      connectedToPhone: null,
      connectedPhoneName: null,
      isCharging: null,
      measuredAt: null,
    );
  }

  DeviceStatusData copyWith({
    int? batteryPercent,
    String? deviceName,
    String? deviceModel,
    bool? connectedToPhone,
    String? connectedPhoneName,
    bool? isCharging,
    String? measuredAt,
  }) {
    return DeviceStatusData(
      batteryPercent: batteryPercent ?? this.batteryPercent,
      deviceName: deviceName ?? this.deviceName,
      deviceModel: deviceModel ?? this.deviceModel,
      connectedToPhone: connectedToPhone ?? this.connectedToPhone,
      connectedPhoneName: connectedPhoneName ?? this.connectedPhoneName,
      isCharging: isCharging ?? this.isCharging,
      measuredAt: measuredAt ?? this.measuredAt,
    );
  }

  String get displayedBattery {
    if (batteryPercent == null) {
      return '--';
    }

    return '$batteryPercent%';
  }

  String get displayedConnection {
    if (connectedToPhone == null) {
      return 'Unknown';
    }

    return connectedToPhone == true ? 'Connected' : 'Disconnected';
  }

  String get displayedCharging {
    if (isCharging == null) {
      return 'Unknown';
    }

    return isCharging == true ? 'Charging' : 'Not charging';
  }

  String get displayedDeviceName {
    if (deviceName == null || deviceName!.isEmpty) {
      return 'Smartwatch';
    }

    return deviceName!;
  }

  String get displayedPhoneName {
    if (connectedPhoneName == null || connectedPhoneName!.isEmpty) {
      return 'No phone detected';
    }

    return connectedPhoneName!;
  }
}
