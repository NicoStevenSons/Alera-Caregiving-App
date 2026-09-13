enum MonitoringDeviceTypeDto {
  watch,
  phone,
  unknown,
}

enum DeviceConnectionStatusDto {
  connected,
  disconnected,
  unknown,
}

class MonitoringDeviceDto {
  final String deviceId;
  final String patientId;
  final MonitoringDeviceTypeDto deviceType;
  final String deviceTypeValue;

  final String? deviceName;
  final String? deviceModel;
  final int? batteryPercent;

  final DeviceConnectionStatusDto connectionStatus;
  final String connectionStatusValue;

  final DateTime? reportedAt;
  final DateTime lastSeenAt;
  final DateTime statusChangedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MonitoringDeviceDto({
    required this.deviceId,
    required this.patientId,
    required this.deviceType,
    required this.deviceTypeValue,
    required this.deviceName,
    required this.deviceModel,
    required this.batteryPercent,
    required this.connectionStatus,
    required this.connectionStatusValue,
    required this.reportedAt,
    required this.lastSeenAt,
    required this.statusChangedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MonitoringDeviceDto.fromJson(Map<String, dynamic> json) {
    final deviceType = _requiredString(
      json['device_type'],
      'device_type',
    );

    final connectionStatus = _requiredString(
      json['connection_status'],
      'connection_status',
    );

    return MonitoringDeviceDto(
      deviceId: _requiredString(json['device_id'], 'device_id'),
      patientId: _requiredString(json['patient_id'], 'patient_id'),

      deviceType: switch (deviceType) {
        'WATCH' => MonitoringDeviceTypeDto.watch,
        'PHONE' => MonitoringDeviceTypeDto.phone,
        _ => MonitoringDeviceTypeDto.unknown,
      },
      deviceTypeValue: deviceType,

      deviceName: json['device_name'] as String?,
      deviceModel: json['device_model'] as String?,
      batteryPercent: json['battery_percent'] as int?,

      connectionStatus: switch (connectionStatus) {
        'CONNECTED' => DeviceConnectionStatusDto.connected,
        'DISCONNECTED' => DeviceConnectionStatusDto.disconnected,
        _ => DeviceConnectionStatusDto.unknown,
      },
      connectionStatusValue: connectionStatus,

      reportedAt: _utcOrNull(json['reported_at']),
      lastSeenAt: _requiredUtc(
        json['last_seen_at'],
        'last_seen_at',
      ),
      statusChangedAt: _requiredUtc(
        json['status_changed_at'],
        'status_changed_at',
      ),
      createdAt: _requiredUtc(
        json['created_at'],
        'created_at',
      ),
      updatedAt: _requiredUtc(
        json['updated_at'],
        'updated_at',
      ),
    );
  }
}

String _requiredString(Object? value, String field) {
  if (value is String) return value;
  throw FormatException('$field must be a string');
}

DateTime _requiredUtc(Object? value, String field) {
  final parsed = _utcOrNull(value);

  if (parsed != null) return parsed;

  throw FormatException('$field must be a timestamp');
}

DateTime? _utcOrNull(Object? value) {
  if (value == null) return null;

  if (value is! String) {
    throw const FormatException(
      'timestamp must be a string',
    );
  }

  final parsed = DateTime.tryParse(value);

  if (parsed == null) {
    throw const FormatException(
      'invalid timestamp',
    );
  }

  return parsed.toUtc();
}