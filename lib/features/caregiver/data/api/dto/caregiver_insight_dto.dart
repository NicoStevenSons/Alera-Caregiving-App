enum CaregiverInsightPriority {
  critical,
  warning,
  informational,
  positive,
  unknown;

  factory CaregiverInsightPriority.fromApi(String? value) {
    return switch (value) {
      'critical' => CaregiverInsightPriority.critical,
      'warning' => CaregiverInsightPriority.warning,
      'informational' => CaregiverInsightPriority.informational,
      'positive' => CaregiverInsightPriority.positive,
      _ => CaregiverInsightPriority.unknown,
    };
  }
}

enum CaregiverInsightSource { aiRanked, fallback }

class CaregiverInsightItemDto {
  final String insightId;
  final CaregiverInsightPriority priority;
  final String title;
  final String message;
  final List<String> evidenceKeys;

  const CaregiverInsightItemDto({
    required this.insightId,
    required this.priority,
    required this.title,
    required this.message,
    required this.evidenceKeys,
  });

  factory CaregiverInsightItemDto.fromJson(Map<String, dynamic> json) {
    final keys = json['evidence_keys'];
    if (keys is! List) {
      throw const FormatException('Insight evidence_keys must be a list.');
    }

    return CaregiverInsightItemDto(
      insightId: json['insight_id'] as String,
      priority: CaregiverInsightPriority.fromApi(json['priority'] as String?),
      title: json['title'] as String,
      message: json['message'] as String,
      evidenceKeys: keys.map((item) => item as String).toList(growable: false),
    );
  }
}

class CaregiverInsightResponseDto {
  final String patientId;
  final String range;
  final DateTime fromAt;
  final DateTime toAt;
  final CaregiverInsightSource source;
  final String summary;
  final List<CaregiverInsightItemDto> items;
  final String disclaimer;

  const CaregiverInsightResponseDto({
    required this.patientId,
    required this.range,
    required this.fromAt,
    required this.toAt,
    required this.source,
    required this.summary,
    required this.items,
    required this.disclaimer,
  });

  factory CaregiverInsightResponseDto.fromJson(Map<String, dynamic> json) {
    final itemList = json['items'];
    if (itemList is! List) {
      throw const FormatException('Caregiver insight items must be a list.');
    }

    return CaregiverInsightResponseDto(
      patientId: json['patient_id'] as String,
      range: json['range'] as String,
      fromAt: DateTime.parse(json['from_at'] as String),
      toAt: DateTime.parse(json['to_at'] as String),
      source: switch (json['source']) {
        'ai_ranked' => CaregiverInsightSource.aiRanked,
        _ => CaregiverInsightSource.fallback,
      },
      summary: json['summary'] as String,
      items: itemList
          .map(
            (item) => CaregiverInsightItemDto.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      disclaimer: json['disclaimer'] as String,
    );
  }
}
