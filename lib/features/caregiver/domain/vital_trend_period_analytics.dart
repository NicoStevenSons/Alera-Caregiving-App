import '../data/api/dto/vital_trend_dto.dart';

class VitalTrendPeriodAnalytics {
  final int warningPeriodCount;
  final int criticalPeriodCount;
  final int abnormalPeriodCount;
  final int? outsideConfiguredRangeCount;

  const VitalTrendPeriodAnalytics({
    required this.warningPeriodCount,
    required this.criticalPeriodCount,
    required this.abnormalPeriodCount,
    required this.outsideConfiguredRangeCount,
  });

  factory VitalTrendPeriodAnalytics.fromTrend(VitalTrendDto trend) {
    final warningPeriodCount = trend.points
        .where((point) => point.severity == VitalTrendSeverity.warning)
        .length;
    final criticalPeriodCount = trend.points
        .where((point) => point.severity == VitalTrendSeverity.critical)
        .length;

    final normalMin = trend.thresholds.normalMin;
    final normalMax = trend.thresholds.normalMax;
    final hasConfiguredRange =
        normalMin != null && normalMax != null && normalMin <= normalMax;

    final outsideConfiguredRangeCount = hasConfiguredRange
        ? trend.points
              .where(
                (point) =>
                    point.minimum < normalMin ||
                    point.maximum > normalMax,
              )
              .length
        : null;

    return VitalTrendPeriodAnalytics(
      warningPeriodCount: warningPeriodCount,
      criticalPeriodCount: criticalPeriodCount,
      abnormalPeriodCount: warningPeriodCount + criticalPeriodCount,
      outsideConfiguredRangeCount: outsideConfiguredRangeCount,
    );
  }
}
