import '../../../domain/models/caregiver_alert.dart';

class CaregiverAlertDto {
  final String alertId;
  final String patientId;
  final String? patientDisplayName;
  final String title;
  final String? evaluationReason;
  final String severity;
  final String metricType;
  final String status;
  final double? readingValue;
  final double? thresholdValue;
  final String? readingUnit;
  final DateTime detectedAt;
  final DateTime? confirmedAt;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  const CaregiverAlertDto({
    required this.alertId,
    required this.patientId,
    required this.patientDisplayName,
    required this.title,
    required this.evaluationReason,
    required this.severity,
    required this.metricType,
    required this.status,
    required this.readingValue,
    required this.thresholdValue,
    required this.readingUnit,
    required this.detectedAt,
    required this.confirmedAt,
    required this.createdAt,
    required this.resolvedAt,
  });

  factory CaregiverAlertDto.fromJson(Map<String, dynamic> json) {
    final String? metricType = _optionalString(json['metric_type']);
    final String? conditionKey = _optionalString(json['condition_key']);
    return CaregiverAlertDto(
      alertId: _requiredString(json, 'alert_id'),
      patientId: _requiredString(json, 'patient_id'),
      patientDisplayName: _optionalString(json['patient_display_name']),
      title: _optionalString(json['title']) ?? 'Health alert',
      evaluationReason: _optionalString(json['evaluation_reason']),
      severity: _requiredString(json, 'severity'),
      metricType: metricType ?? _metricFromCondition(conditionKey),
      status: _requiredString(json, 'status'),
      readingValue: _optionalDouble(json, 'reading_value'),
      thresholdValue: _optionalDouble(json, 'threshold_value'),
      readingUnit: _optionalString(json['reading_unit']),
      detectedAt: _requiredDateTime(json, 'detected_at'),
      confirmedAt: _optionalDateTime(json, 'confirmed_at'),
      createdAt: _optionalDateTime(json, 'created_at'),
      resolvedAt: _optionalDateTime(json, 'resolved_at'),
    );
  }

  CaregiverAlert toDomain() {
    return CaregiverAlert(
      id: alertId,
      careRecipientId: patientId,
      patientDisplayName: patientDisplayName,
      title: title,
      description: evaluationReason ?? '',
      severity: switch (severity) {
        'WARNING' => CaregiverAlertSeverity.warning,
        'CRITICAL' => CaregiverAlertSeverity.critical,
        _ => throw FormatException('Unsupported alert severity: $severity'),
      },
      metric: switch (metricType) {
        'HEART_RATE' => CaregiverAlertMetric.heartRate,
        'SPO2' => CaregiverAlertMetric.spo2,
        'BATTERY_LEVEL' => CaregiverAlertMetric.watchBattery,
        'CONNECTION_STATUS' ||
        'INACTIVITY' ||
        'ACTIVITY' ||
        'SLEEP' ||
        'SYNC_STATUS' => CaregiverAlertMetric.system,
        _ => CaregiverAlertMetric.system,
      },
      status: switch (status) {
        'ACTIVE' => CaregiverAlertStatus.active,
        'ACKNOWLEDGED' => CaregiverAlertStatus.acknowledged,
        'RESOLVED' => CaregiverAlertStatus.resolved,
        'FALSE_ALARM' => CaregiverAlertStatus.falseAlarm,
        'ARCHIVED' => CaregiverAlertStatus.resolved,
        _ => throw FormatException('Unsupported alert status: $status'),
      },
      reading: readingValue ?? 0,
      threshold: thresholdValue,
      unit: readingUnit ?? '',
      triggerDuration: confirmedAt?.difference(detectedAt),
      detectedAt: detectedAt,
      confirmedAt: confirmedAt,
      createdAt: createdAt,
      resolvedAt: resolvedAt,
      timeline: const [],
    );
  }
}

class CaregiverAlertsResponseDto {
  final List<CaregiverAlertDto> items;
  final int total;
  final int limit;
  final int offset;

  const CaregiverAlertsResponseDto({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory CaregiverAlertsResponseDto.fromJson(Map<String, dynamic> json) {
    final Object? rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('Alerts response "items" must be a list.');
    }
    return CaregiverAlertsResponseDto(
      items: rawItems
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Each alert must be a JSON object.');
            }
            return CaregiverAlertDto.fromJson(item);
          })
          .toList(growable: false),
      total: _requiredInt(json, 'total'),
      limit: _requiredInt(json, 'limit'),
      offset: _requiredInt(json, 'offset'),
    );
  }
}

class AlertActionDto {
  final String actionType;
  final String? note;
  final Map<String, dynamic> metadata;
  final DateTime performedAt;

  const AlertActionDto({
    required this.actionType,
    required this.note,
    required this.metadata,
    required this.performedAt,
  });

  factory AlertActionDto.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['action_metadata'];
    return AlertActionDto(
      actionType: _requiredString(json, 'action_type'),
      note: _optionalString(json['action_note']),
      metadata: rawMetadata is Map<String, dynamic> ? rawMetadata : const {},
      performedAt: _requiredDateTime(json, 'performed_at'),
    );
  }

  AlertTimelineEntry toDomain() {
    final description = switch (actionType) {
      'ACKNOWLEDGE' => note ?? 'The caregiver marked this alert as seen.',
      'RESOLVE' => note ?? 'The caregiver marked this alert as resolved.',
      'MARK_FALSE_ALARM' =>
        note ?? 'The caregiver marked this as a false alarm.',
      'ADD_NOTE' => note ?? 'The caregiver added a note.',
      'LOG_INTERVENTION' =>
        note ?? 'The caregiver recorded how they responded.',
      'ESCALATE' => _escalationDescription(),
      _ => note ?? 'The alert was updated.',
    };
    return AlertTimelineEntry(
      occurredAt: performedAt,
      title: switch (actionType) {
        'ACKNOWLEDGE' => 'Seen by caregiver',
        'RESOLVE' => 'Marked as resolved',
        'MARK_FALSE_ALARM' => 'Marked as false alarm',
        'ADD_NOTE' => 'Caregiver added a note',
        'LOG_INTERVENTION' => 'Caregiver recorded an action',
        'ESCALATE' => 'Alert became critical',
        _ => 'Alert updated',
      },
      description: description,
    );
  }

  String _escalationDescription() {
    final value = _optionalString(metadata['reading_value']);
    final unit = _optionalString(metadata['reading_unit']);
    final seconds = _optionalInt(metadata['seconds_since_confirmed']);
    final elapsed = seconds == null ? null : _durationLabel(seconds);
    final reading = value == null
        ? 'The reading reached the critical range'
        : 'The reading reached $value${unit == null ? '' : ' $unit'}';
    final timing = elapsed == null
        ? ''
        : ', $elapsed after the warning was sent';
    return '$reading$timing.';
  }
}

int? _optionalInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

String _durationLabel(int totalSeconds) {
  if (totalSeconds < 60) return '$totalSeconds seconds';
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return seconds == 0 ? '$minutes minutes' : '$minutes min $seconds sec';
}

String _requiredString(Map<String, dynamic> json, String key) {
  final String? value = _optionalString(json[key]);
  if (value == null) throw FormatException('Missing or invalid "$key".');
  return value;
}

String? _optionalString(Object? value) {
  if (value is! String) return null;
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

double? _optionalDouble(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    final double? parsed = double.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('Invalid numeric value for "$key".');
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is int) return value;
  if (value is num && value == value.roundToDouble()) return value.toInt();
  if (value is String) {
    final int? parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('Missing or invalid "$key".');
}

DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
  final DateTime? parsed = _optionalDateTime(json, key);
  if (parsed == null) throw FormatException('Missing or invalid "$key".');
  return parsed;
}

DateTime? _optionalDateTime(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value == null) return null;
  if (value is String) {
    final DateTime? parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return null;
}

String _metricFromCondition(String? conditionKey) {
  return switch (conditionKey) {
    'HR_HIGH' || 'HR_LOW' => 'HEART_RATE',
    'SPO2_LOW' => 'SPO2',
    'PHONE_BATTERY_LOW' || 'WATCH_BATTERY_LOW' => 'BATTERY_LEVEL',
    'PHONE_DISCONNECTED' || 'WATCH_DISCONNECTED' => 'CONNECTION_STATUS',
    'INACTIVITY' => 'INACTIVITY',
    _ => 'SYSTEM',
  };
}
