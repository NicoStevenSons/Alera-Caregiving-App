class CreatePatientRequest {
  final String fullName;
  final DateTime? birthdate;
  final String? sex;
  final String? phoneNumber;
  final String? addressOrRoom;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? knownConditions;
  final String? medications;
  final num? baselineHeartRate;
  final num? baselineSpo2;
  final String? monitoringNotes;

  const CreatePatientRequest({
    required this.fullName,
    this.birthdate,
    this.sex,
    this.phoneNumber,
    this.addressOrRoom,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.knownConditions,
    this.medications,
    this.baselineHeartRate,
    this.baselineSpo2,
    this.monitoringNotes,
  });

  Map<String, Object?> toJson() => {
    'full_name': fullName.trim(),
    'birthdate': birthdate == null
        ? null
        : '${birthdate!.year.toString().padLeft(4, '0')}-'
              '${birthdate!.month.toString().padLeft(2, '0')}-'
              '${birthdate!.day.toString().padLeft(2, '0')}',
    'sex': sex,
    'phone_number': _trimmedOrNull(phoneNumber),
    'address_or_room': _trimmedOrNull(addressOrRoom),
    'emergency_contact_name': _trimmedOrNull(emergencyContactName),
    'emergency_contact_phone': _trimmedOrNull(emergencyContactPhone),
    'known_conditions': _trimmedOrNull(knownConditions),
    'medications': _trimmedOrNull(medications),
    'baseline_heart_rate': baselineHeartRate,
    'baseline_spo2': baselineSpo2,
    'monitoring_notes': _trimmedOrNull(monitoringNotes),
  };
}

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

class PatientCreatedResponse {
  final String patientId;
  final String userId;
  final String householdId;
  final String accountStatus;
  final Object? assignment;
  final String fullName;
  final DateTime? birthdate;
  final String? sex;
  final String? phoneNumber;
  final String? addressOrRoom;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? knownConditions;
  final String? medications;
  final double? baselineHeartRate;
  final double? baselineSpo2;
  final String? monitoringNotes;
  final DateTime createdAt;

  const PatientCreatedResponse({
    required this.patientId,
    required this.userId,
    required this.householdId,
    required this.accountStatus,
    required this.assignment,
    required this.fullName,
    required this.birthdate,
    required this.sex,
    required this.phoneNumber,
    required this.addressOrRoom,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.knownConditions,
    required this.medications,
    required this.baselineHeartRate,
    required this.baselineSpo2,
    required this.monitoringNotes,
    required this.createdAt,
  });

  factory PatientCreatedResponse.fromJson(Map<String, dynamic> json) {
    return PatientCreatedResponse(
      patientId: json['patient_id'] as String,
      userId: json['user_id'] as String,
      householdId: json['household_id'] as String,
      accountStatus: json['account_status'] as String,
      assignment: json['assignment'],
      fullName: json['full_name'] as String,
      birthdate: _dateOrNull(json['birthdate']),
      sex: json['sex'] as String?,
      phoneNumber: json['phone_number'] as String?,
      addressOrRoom: json['address_or_room'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      knownConditions: json['known_conditions'] as String?,
      medications: json['medications'] as String?,
      baselineHeartRate: _decimalOrNull(json['baseline_heart_rate']),
      baselineSpo2: _decimalOrNull(json['baseline_spo2']),
      monitoringNotes: json['monitoring_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

enum PatientMonitoringStatus { critical, warning, stable, noData, unknown }

enum PatientDeviceConnectionStatus {
  notConnected,
  connected,
  syncing,
  failed,
  disconnected,
  unknown,
}

class LatestMetricReadingDto {
  final double value;
  final String? unit;
  final DateTime recordedAt;

  const LatestMetricReadingDto({
    required this.value,
    required this.unit,
    required this.recordedAt,
  });

  factory LatestMetricReadingDto.fromJson(Map<String, dynamic> json) =>
      LatestMetricReadingDto(
        value: _requiredDecimal(json['value'], 'value'),
        unit: json['unit'] as String?,
        recordedAt: _requiredUtc(json['recorded_at'], 'recorded_at'),
      );
}

class CurrentHealthSummaryDto {
  final LatestMetricReadingDto? latestHeartRate;
  final LatestMetricReadingDto? latestSpo2;
  final DateTime? lastCheckIn;
  final int activeAlertCount;
  final String? highestActiveAlertSeverity;
  final PatientMonitoringStatus monitoringStatus;
  final String monitoringStatusValue;
  final PatientDeviceConnectionStatus deviceConnectionStatus;
  final String deviceConnectionStatusValue;
  final DateTime? lastDeviceSyncAt;

  const CurrentHealthSummaryDto({
    required this.latestHeartRate,
    required this.latestSpo2,
    required this.lastCheckIn,
    required this.activeAlertCount,
    required this.highestActiveAlertSeverity,
    required this.monitoringStatus,
    required this.monitoringStatusValue,
    required this.deviceConnectionStatus,
    required this.deviceConnectionStatusValue,
    required this.lastDeviceSyncAt,
  });

  factory CurrentHealthSummaryDto.fromJson(Map<String, dynamic> json) {
    final monitoring = _requiredString(
      json['monitoring_status'],
      'monitoring_status',
    );
    final connection = _requiredString(
      json['device_connection_status'],
      'device_connection_status',
    );
    return CurrentHealthSummaryDto(
      latestHeartRate: _readingOrNull(json['latest_heart_rate']),
      latestSpo2: _readingOrNull(json['latest_spo2']),
      lastCheckIn: _utcOrNull(json['last_check_in']),
      activeAlertCount: _requiredInt(
        json['active_alert_count'],
        'active_alert_count',
      ),
      highestActiveAlertSeverity:
          json['highest_active_alert_severity'] as String?,
      monitoringStatus: switch (monitoring) {
        'CRITICAL' => PatientMonitoringStatus.critical,
        'WARNING' => PatientMonitoringStatus.warning,
        'STABLE' => PatientMonitoringStatus.stable,
        'NO_DATA' => PatientMonitoringStatus.noData,
        _ => PatientMonitoringStatus.unknown,
      },
      monitoringStatusValue: monitoring,
      deviceConnectionStatus: switch (connection) {
        'NOT_CONNECTED' => PatientDeviceConnectionStatus.notConnected,
        'CONNECTED' => PatientDeviceConnectionStatus.connected,
        'SYNCING' => PatientDeviceConnectionStatus.syncing,
        'FAILED' => PatientDeviceConnectionStatus.failed,
        'DISCONNECTED' => PatientDeviceConnectionStatus.disconnected,
        _ => PatientDeviceConnectionStatus.unknown,
      },
      deviceConnectionStatusValue: connection,
      lastDeviceSyncAt: _utcOrNull(json['last_device_sync_at']),
    );
  }
}

class PatientAssignmentDto {
  final String assignmentId;
  final String caregiverUserId;
  final String patientId;
  final String assignedByUserId;
  final DateTime assignedAt;
  final DateTime? unassignedAt;

  const PatientAssignmentDto({
    required this.assignmentId,
    required this.caregiverUserId,
    required this.patientId,
    required this.assignedByUserId,
    required this.assignedAt,
    required this.unassignedAt,
  });

  factory PatientAssignmentDto.fromJson(Map<String, dynamic> json) =>
      PatientAssignmentDto(
        assignmentId: _requiredString(json['assignment_id'], 'assignment_id'),
        caregiverUserId: _requiredString(
          json['caregiver_user_id'],
          'caregiver_user_id',
        ),
        patientId: _requiredString(json['patient_id'], 'patient_id'),
        assignedByUserId: _requiredString(
          json['assigned_by_user_id'],
          'assigned_by_user_id',
        ),
        assignedAt: _requiredUtc(json['assigned_at'], 'assigned_at'),
        unassignedAt: _utcOrNull(json['unassigned_at']),
      );
}

class PatientListItemDto {
  final String patientId;
  final String userId;
  final String householdId;
  final String fullName;
  final DateTime? birthdate;
  final String? sex;
  final String? phoneNumber;
  final String? addressOrRoom;
  final String accountStatus;
  final DateTime createdAt;
  final CurrentHealthSummaryDto currentSummary;

  const PatientListItemDto({
    required this.patientId,
    required this.userId,
    required this.householdId,
    required this.fullName,
    required this.birthdate,
    required this.sex,
    required this.phoneNumber,
    required this.addressOrRoom,
    required this.accountStatus,
    required this.createdAt,
    required this.currentSummary,
  });

  factory PatientListItemDto.fromJson(Map<String, dynamic> json) =>
      PatientListItemDto(
        patientId: _requiredString(json['patient_id'], 'patient_id'),
        userId: _requiredString(json['user_id'], 'user_id'),
        householdId: _requiredString(json['household_id'], 'household_id'),
        fullName: _requiredString(json['full_name'], 'full_name'),
        birthdate: _dateOrNull(json['birthdate']),
        sex: json['sex'] as String?,
        phoneNumber: json['phone_number'] as String?,
        addressOrRoom: json['address_or_room'] as String?,
        accountStatus: _requiredString(
          json['account_status'],
          'account_status',
        ),
        createdAt: _requiredUtc(json['created_at'], 'created_at'),
        currentSummary: CurrentHealthSummaryDto.fromJson(
          _requiredMap(json['current_summary'], 'current_summary'),
        ),
      );
}

class PaginatedPatientListDto {
  final List<PatientListItemDto> items;
  final int total;
  final int limit;
  final int offset;

  const PaginatedPatientListDto({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory PaginatedPatientListDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) throw const FormatException('items must be a list');
    return PaginatedPatientListDto(
      items: rawItems
          .map(
            (item) => PatientListItemDto.fromJson(_requiredMap(item, 'item')),
          )
          .toList(growable: false),
      total: _requiredInt(json['total'], 'total'),
      limit: _requiredInt(json['limit'], 'limit'),
      offset: _requiredInt(json['offset'], 'offset'),
    );
  }
}

class PatientDetailDto extends PatientListItemDto {
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? knownConditions;
  final String? medications;
  final double? baselineHeartRate;
  final double? baselineSpo2;
  final String? monitoringNotes;
  final DateTime? archivedAt;
  final PatientAssignmentDto? assignment;

  const PatientDetailDto({
    required super.patientId,
    required super.userId,
    required super.householdId,
    required super.fullName,
    required super.birthdate,
    required super.sex,
    required super.phoneNumber,
    required super.addressOrRoom,
    required super.accountStatus,
    required super.createdAt,
    required super.currentSummary,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.knownConditions,
    required this.medications,
    required this.baselineHeartRate,
    required this.baselineSpo2,
    required this.monitoringNotes,
    required this.archivedAt,
    required this.assignment,
  });

  factory PatientDetailDto.fromJson(Map<String, dynamic> json) {
    final base = PatientListItemDto.fromJson(json);
    final assignment = json['assignment'];
    return PatientDetailDto(
      patientId: base.patientId,
      userId: base.userId,
      householdId: base.householdId,
      fullName: base.fullName,
      birthdate: base.birthdate,
      sex: base.sex,
      phoneNumber: base.phoneNumber,
      addressOrRoom: base.addressOrRoom,
      accountStatus: base.accountStatus,
      createdAt: base.createdAt,
      currentSummary: base.currentSummary,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      knownConditions: json['known_conditions'] as String?,
      medications: json['medications'] as String?,
      baselineHeartRate: _decimalOrNull(json['baseline_heart_rate']),
      baselineSpo2: _decimalOrNull(json['baseline_spo2']),
      monitoringNotes: json['monitoring_notes'] as String?,
      archivedAt: _utcOrNull(json['archived_at']),
      assignment: assignment == null
          ? null
          : PatientAssignmentDto.fromJson(
              _requiredMap(assignment, 'assignment'),
            ),
    );
  }
}

double? _decimalOrNull(Object? value) => switch (value) {
  num number => number.toDouble(),
  String text => double.tryParse(text),
  _ => null,
};

DateTime? _dateOrNull(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

LatestMetricReadingDto? _readingOrNull(Object? value) => value == null
    ? null
    : LatestMetricReadingDto.fromJson(_requiredMap(value, 'latest reading'));

Map<String, dynamic> _requiredMap(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  throw FormatException('$field must be an object');
}

String _requiredString(Object? value, String field) {
  if (value is String) return value;
  throw FormatException('$field must be a string');
}

int _requiredInt(Object? value, String field) {
  if (value is int) return value;
  throw FormatException('$field must be an integer');
}

double _requiredDecimal(Object? value, String field) {
  final parsed = _decimalOrNull(value);
  if (parsed != null) return parsed;
  throw FormatException('$field must be numeric');
}

DateTime _requiredUtc(Object? value, String field) {
  final parsed = _utcOrNull(value);
  if (parsed != null) return parsed;
  throw FormatException('$field must be a timestamp');
}

DateTime? _utcOrNull(Object? value) {
  if (value == null) return null;
  if (value is! String) {
    throw const FormatException('timestamp must be a string');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw const FormatException('invalid timestamp');
  return parsed.toUtc();
}

class PatientAccessCodeResponse {
  final String accessCodeId;
  final String patientId;
  final String accessCode;
  final String createdByUserId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String status;

  const PatientAccessCodeResponse({
    required this.accessCodeId,
    required this.patientId,
    required this.accessCode,
    required this.createdByUserId,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
  });

  factory PatientAccessCodeResponse.fromJson(Map<String, dynamic> json) =>
      PatientAccessCodeResponse(
        accessCodeId: json['access_code_id'] as String,
        patientId: json['patient_id'] as String,
        accessCode: json['access_code'] as String,
        createdByUserId: json['created_by_user_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        expiresAt: DateTime.parse(json['expires_at'] as String),
        status: json['status'] as String,
      );
}
