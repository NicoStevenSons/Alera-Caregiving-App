enum VitalTrendMetric {
  heartRate,
  spo2;

  String get apiValue => switch (this) {
    VitalTrendMetric.heartRate => 'HEART_RATE',
    VitalTrendMetric.spo2 => 'SPO2',
  };

  String get label => switch (this) {
    VitalTrendMetric.heartRate => 'Heart Rate',
    VitalTrendMetric.spo2 => 'SpO₂',
  };
}

enum VitalTrendRange {
  day,
  week,
  month;

  String get apiValue => switch (this) {
    VitalTrendRange.day => '24h',
    VitalTrendRange.week => '7d',
    VitalTrendRange.month => '30d',
  };

  String get label => switch (this) {
    VitalTrendRange.day => '24H',
    VitalTrendRange.week => '7D',
    VitalTrendRange.month => '30D',
  };
}

enum VitalTrendSeverity {
  info,
  warning,
  critical,
  unknown;

  factory VitalTrendSeverity.fromApi(String? value) {
    return switch (value) {
      'INFO' => VitalTrendSeverity.info,
      'WARNING' => VitalTrendSeverity.warning,
      'CRITICAL' => VitalTrendSeverity.critical,
      _ => VitalTrendSeverity.unknown,
    };
  }
}

class VitalTrendSummaryDto {
  final double? latest;
  final double? average;
  final double? minimum;
  final double? maximum;
  final int readingCount;

  const VitalTrendSummaryDto({
    required this.latest,
    required this.average,
    required this.minimum,
    required this.maximum,
    required this.readingCount,
  });

  factory VitalTrendSummaryDto.fromJson(Map<String, dynamic> json) {
    return VitalTrendSummaryDto(
      latest: _toDouble(json['latest']),
      average: _toDouble(json['average']),
      minimum: _toDouble(json['minimum']),
      maximum: _toDouble(json['maximum']),
      readingCount: (json['reading_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class VitalTrendThresholdsDto {
  final double? normalMin;
  final double? normalMax;

  const VitalTrendThresholdsDto({
    required this.normalMin,
    required this.normalMax,
  });

  factory VitalTrendThresholdsDto.fromJson(Map<String, dynamic> json) {
    return VitalTrendThresholdsDto(
      normalMin: _toDouble(json['normal_min']),
      normalMax: _toDouble(json['normal_max']),
    );
  }
}

class VitalTrendPointDto {
  final DateTime recordedAt;
  final double value;
  final double minimum;
  final double maximum;
  final int readingCount;
  final VitalTrendSeverity severity;

  const VitalTrendPointDto({
    required this.recordedAt,
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.readingCount,
    required this.severity,
  });

  factory VitalTrendPointDto.fromJson(Map<String, dynamic> json) {
    final recordedAt = json['recorded_at'] as String?;
    final value = _toDouble(json['value']);
    final minimum = _toDouble(json['minimum']);
    final maximum = _toDouble(json['maximum']);

    if (recordedAt == null ||
        value == null ||
        minimum == null ||
        maximum == null) {
      throw const FormatException('Invalid vital trend point.');
    }

    return VitalTrendPointDto(
      recordedAt: DateTime.parse(recordedAt),
      value: value,
      minimum: minimum,
      maximum: maximum,
      readingCount: (json['reading_count'] as num?)?.toInt() ?? 0,
      severity: VitalTrendSeverity.fromApi(json['severity'] as String?),
    );
  }
}

class VitalTrendDto {
  final String patientId;
  final String metricType;
  final String unit;
  final String range;
  final String resolution;

  final DateTime fromAt;
  final DateTime toAt;

  final VitalTrendSummaryDto summary;
  final VitalTrendThresholdsDto thresholds;
  final List<VitalTrendPointDto> points;

  const VitalTrendDto({
    required this.patientId,
    required this.metricType,
    required this.unit,
    required this.range,
    required this.resolution,
    required this.fromAt,
    required this.toAt,
    required this.summary,
    required this.thresholds,
    required this.points,
  });

  factory VitalTrendDto.fromJson(Map<String, dynamic> json) {
    final pointList = json['points'];

    if (pointList is! List) {
      throw const FormatException('Vital trend points must be a list.');
    }

    return VitalTrendDto(
      patientId: json['patient_id'] as String,
      metricType: json['metric_type'] as String,
      unit: json['unit'] as String,
      range: json['range'] as String,
      resolution: json['resolution'] as String,
      fromAt: DateTime.parse(json['from_at'] as String),
      toAt: DateTime.parse(json['to_at'] as String),
      summary: VitalTrendSummaryDto.fromJson(
        Map<String, dynamic>.from(json['summary'] as Map),
      ),
      thresholds: VitalTrendThresholdsDto.fromJson(
        Map<String, dynamic>.from(json['thresholds'] as Map),
      ),
      points: pointList
          .map(
            (item) => VitalTrendPointDto.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

double? _toDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
