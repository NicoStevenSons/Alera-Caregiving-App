enum CaregiverAlertSeverity { warning, critical }

enum CaregiverAlertMetric { heartRate, spo2, watchBattery }

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
  final String title;
  final String description;
  final CaregiverAlertSeverity severity;
  final CaregiverAlertMetric metric;
  final CaregiverAlertStatus status;
  final double reading;
  final double? threshold;
  final String unit;
  final Duration? triggerDuration;
  final DateTime detectedAt;
  final DateTime? confirmedAt;
  final DateTime? resolvedAt;
  final List<AlertTimelineEntry> timeline;
  final String? note;

  const CaregiverAlert({
    required this.id,
    required this.careRecipientId,
    this.patientDisplayName,
    required this.title,
    required this.description,
    required this.severity,
    required this.metric,
    required this.status,
    required this.reading,
    required this.threshold,
    required this.unit,
    required this.triggerDuration,
    required this.detectedAt,
    this.confirmedAt,
    this.resolvedAt,
    required this.timeline,
    this.note,
  });
}
