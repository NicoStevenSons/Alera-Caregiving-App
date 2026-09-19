enum CaregiverAlertSeverity { warning, critical }

enum CaregiverAlertMetric {
  heartRate,
  spo2,
  activity,
  sleep,
  watchBattery,
  system,
}

enum CaregiverAlertStatus { active, acknowledged, resolved, falseAlarm }

class AlertTimelineEntry {
  final DateTime occurredAt;
  final String title;
  final String description;

  const AlertTimelineEntry({
    required this.occurredAt,
    required this.title,
    required this.description,
  });
}

class CaregiverAlert {
  final String id;
  final String careRecipientId;
  final String? patientDisplayName;
  final String? conditionKey;
  final String title;
  final String description;
  final CaregiverAlertSeverity severity;
  final CaregiverAlertMetric metric;
  final CaregiverAlertStatus status;
  final bool hasReading;
  final double reading;
  final double? threshold;
  final String unit;
  final Duration? triggerDuration;
  final DateTime detectedAt;
  final DateTime? confirmedAt;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final List<AlertTimelineEntry> timeline;
  final String? note;

  const CaregiverAlert({
    required this.id,
    required this.careRecipientId,
    this.patientDisplayName,
    this.conditionKey,
    required this.title,
    required this.description,
    required this.severity,
    required this.metric,
    required this.status,
    this.hasReading = true,
    required this.reading,
    required this.threshold,
    required this.unit,
    required this.triggerDuration,
    required this.detectedAt,
    this.confirmedAt,
    this.createdAt,
    this.resolvedAt,
    required this.timeline,
    this.note,
  });

  CaregiverAlert copyWith({
    CaregiverAlertSeverity? severity,
    CaregiverAlertStatus? status,
    DateTime? resolvedAt,
    List<AlertTimelineEntry>? timeline,
    String? note,
  }) {
    return CaregiverAlert(
      id: id,
      careRecipientId: careRecipientId,
      patientDisplayName: patientDisplayName,
      conditionKey: conditionKey,
      title: title,
      description: description,
      severity: severity ?? this.severity,
      metric: metric,
      status: status ?? this.status,
      hasReading: hasReading,
      reading: reading,
      threshold: threshold,
      unit: unit,
      triggerDuration: triggerDuration,
      detectedAt: detectedAt,
      confirmedAt: confirmedAt,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      timeline: timeline ?? this.timeline,
      note: note ?? this.note,
    );
  }
}
