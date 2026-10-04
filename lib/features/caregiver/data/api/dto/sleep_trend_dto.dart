enum SleepTrendRange {
  week,
  month;

  String get apiValue => switch (this) {
    SleepTrendRange.week => '7d',
    SleepTrendRange.month => '30d',
  };

  String get label => switch (this) {
    SleepTrendRange.week => '7D',
    SleepTrendRange.month => '30D',
  };
}

class SleepTrendPointDto {
  final DateTime activityDate;
  final int durationSeconds;

  const SleepTrendPointDto({
    required this.activityDate,
    required this.durationSeconds,
  });

  factory SleepTrendPointDto.fromJson(Map<String, dynamic> json) {
    final activityDate = json['activity_date'];
    final durationSeconds = json['duration_seconds'];

    if (activityDate is! String || durationSeconds is! num) {
      throw const FormatException('Invalid sleep trend point.');
    }

    return SleepTrendPointDto(
      activityDate: DateTime.parse(activityDate),
      durationSeconds: durationSeconds.toInt(),
    );
  }
}

class SleepTrendSummaryDto {
  final SleepTrendPointDto? latestNight;
  final double? averageDurationSeconds;
  final SleepTrendPointDto? longestNight;
  final SleepTrendPointDto? shortestNight;
  final int nightsWithData;

  const SleepTrendSummaryDto({
    required this.latestNight,
    required this.averageDurationSeconds,
    required this.longestNight,
    required this.shortestNight,
    required this.nightsWithData,
  });

  factory SleepTrendSummaryDto.fromJson(Map<String, dynamic> json) {
    return SleepTrendSummaryDto(
      latestNight: _pointOrNull(json['latest_night']),
      averageDurationSeconds: _toDouble(json['average_duration_seconds']),
      longestNight: _pointOrNull(json['longest_night']),
      shortestNight: _pointOrNull(json['shortest_night']),
      nightsWithData: (json['nights_with_data'] as num?)?.toInt() ?? 0,
    );
  }
}

class SleepTrendDto {
  final String patientId;
  final String range;
  final DateTime fromDate;
  final DateTime toDate;
  final SleepTrendSummaryDto summary;
  final List<SleepTrendPointDto> points;

  const SleepTrendDto({
    required this.patientId,
    required this.range,
    required this.fromDate,
    required this.toDate,
    required this.summary,
    required this.points,
  });

  factory SleepTrendDto.fromJson(Map<String, dynamic> json) {
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
      throw const FormatException('Invalid sleep trend response.');
    }

    return SleepTrendDto(
      patientId: patientId,
      range: range,
      fromDate: DateTime.parse(fromDate),
      toDate: DateTime.parse(toDate),
      summary: SleepTrendSummaryDto.fromJson(
        Map<String, dynamic>.from(summary),
      ),
      points: points
          .map(
            (item) => SleepTrendPointDto.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

SleepTrendPointDto? _pointOrNull(Object? value) {
  if (value == null) return null;

  if (value is! Map) {
    throw const FormatException('Invalid sleep trend summary point.');
  }

  return SleepTrendPointDto.fromJson(Map<String, dynamic>.from(value));
}

double? _toDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
