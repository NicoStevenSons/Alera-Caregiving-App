enum ActivityTrendRange {
  week,
  month;

  String get apiValue => switch (this) {
    ActivityTrendRange.week => '7d',
    ActivityTrendRange.month => '30d',
  };

  String get label => switch (this) {
    ActivityTrendRange.week => '7D',
    ActivityTrendRange.month => '30D',
  };
}

class ActivityTrendPointDto {
  final DateTime activityDate;
  final int totalSteps;

  const ActivityTrendPointDto({
    required this.activityDate,
    required this.totalSteps,
  });

  factory ActivityTrendPointDto.fromJson(Map<String, dynamic> json) {
    final activityDate = json['activity_date'];
    final totalSteps = json['total_steps'];

    if (activityDate is! String || totalSteps is! num) {
      throw const FormatException('Invalid activity trend point.');
    }

    return ActivityTrendPointDto(
      activityDate: DateTime.parse(activityDate),
      totalSteps: totalSteps.toInt(),
    );
  }
}

class ActivityTrendSummaryDto {
  final double? averageStepsPerDay;
  final ActivityTrendPointDto? highestDay;
  final ActivityTrendPointDto? lowestDay;
  final int daysWithData;

  const ActivityTrendSummaryDto({
    required this.averageStepsPerDay,
    required this.highestDay,
    required this.lowestDay,
    required this.daysWithData,
  });

  factory ActivityTrendSummaryDto.fromJson(Map<String, dynamic> json) {
    return ActivityTrendSummaryDto(
      averageStepsPerDay: _toDouble(json['average_steps_per_day']),
      highestDay: _pointOrNull(json['highest_day']),
      lowestDay: _pointOrNull(json['lowest_day']),
      daysWithData: (json['days_with_data'] as num?)?.toInt() ?? 0,
    );
  }
}

class ActivityTrendDto {
  final String patientId;
  final String range;
  final DateTime fromDate;
  final DateTime toDate;
  final ActivityTrendSummaryDto summary;
  final List<ActivityTrendPointDto> points;

  const ActivityTrendDto({
    required this.patientId,
    required this.range,
    required this.fromDate,
    required this.toDate,
    required this.summary,
    required this.points,
  });

  factory ActivityTrendDto.fromJson(Map<String, dynamic> json) {
    final patientId = json['patient_id'];
    final range = json['range'];
    final fromDate = json['from_date'];
    final toDate = json['to_date'];
    final summary = json['summary'];
    final points = json['points'];

    if (patientId is! String ||
        range is! String ||
        fromDate is! String ||
        toDate is! String ||
        summary is! Map ||
        points is! List) {
      throw const FormatException('Invalid activity trend response.');
    }

    return ActivityTrendDto(
      patientId: patientId,
      range: range,
      fromDate: DateTime.parse(fromDate),
      toDate: DateTime.parse(toDate),
      summary: ActivityTrendSummaryDto.fromJson(
        Map<String, dynamic>.from(summary),
      ),
      points: points
          .map(
            (item) => ActivityTrendPointDto.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

ActivityTrendPointDto? _pointOrNull(Object? value) {
  if (value == null) return null;

  if (value is! Map) {
    throw const FormatException('Invalid activity trend summary point.');
  }

  return ActivityTrendPointDto.fromJson(Map<String, dynamic>.from(value));
}

double? _toDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
