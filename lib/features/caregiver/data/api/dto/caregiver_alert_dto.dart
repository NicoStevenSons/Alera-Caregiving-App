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
        _ => throw FormatException('Unsupported alert metric: $metricType'),
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
    _ => throw const FormatException('Missing or invalid "metric_type".'),
  };
}
