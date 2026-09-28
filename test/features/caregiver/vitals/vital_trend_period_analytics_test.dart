import 'package:alera/features/caregiver/data/api/dto/vital_trend_dto.dart';
import 'package:alera/features/caregiver/domain/vital_trend_period_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VitalTrendPeriodAnalytics', () {
    test('counts warning, critical, abnormal, and outside-range periods', () {
      final analytics = VitalTrendPeriodAnalytics.fromTrend(
        _trend(
          thresholds: const VitalTrendThresholdsDto(
            normalMin: 60,
            normalMax: 100,
          ),
          points: [
            _point(70, minimum: 65, maximum: 80),
            _point(
              105,
              minimum: 95,
              maximum: 115,
              severity: VitalTrendSeverity.warning,
              day: 2,
            ),
            _point(
              90,
              minimum: 55,
              maximum: 130,
              severity: VitalTrendSeverity.critical,
              day: 3,
            ),
          ],
        ),
      );

      expect(analytics.warningPeriodCount, 1);
      expect(analytics.criticalPeriodCount, 1);
      expect(analytics.abnormalPeriodCount, 2);
      expect(analytics.outsideConfiguredRangeCount, 2);
    });

    test('does not invent outside-range count without both thresholds', () {
      final analytics = VitalTrendPeriodAnalytics.fromTrend(
        _trend(
          thresholds: const VitalTrendThresholdsDto(
            normalMin: null,
            normalMax: 100,
          ),
          points: [_point(90)],
        ),
      );

      expect(analytics.outsideConfiguredRangeCount, isNull);
    });

    test('outside-range count is independent from severity', () {
      final analytics = VitalTrendPeriodAnalytics.fromTrend(
        _trend(
          thresholds: const VitalTrendThresholdsDto(
            normalMin: 60,
            normalMax: 100,
          ),
          points: [
            _point(90, minimum: 55, maximum: 95),
            _point(
              90,
              minimum: 70,
              maximum: 95,
              severity: VitalTrendSeverity.critical,
              day: 2,
            ),
          ],
        ),
      );

      expect(analytics.outsideConfiguredRangeCount, 1);
      expect(analytics.criticalPeriodCount, 1);
    });
  });
}

VitalTrendDto _trend({
  required VitalTrendThresholdsDto thresholds,
  required List<VitalTrendPointDto> points,
}) {
  return VitalTrendDto(
    patientId: 'patient',
    metricType: 'HEART_RATE',
    unit: 'bpm',
    range: '30d',
    resolution: '1d',
    fromAt: DateTime.utc(2026, 9, 1),
    toAt: DateTime.utc(2026, 10, 1),
    summary: VitalTrendSummaryDto(
      latest: points.isEmpty ? null : points.last.value,
      average: 90,
      minimum: 55,
      maximum: 130,
      readingCount: points.fold(
        0,
        (total, point) => total + point.readingCount,
      ),
    ),
    thresholds: thresholds,
    points: points,
  );
}

VitalTrendPointDto _point(
  double value, {
  double? minimum,
  double? maximum,
  VitalTrendSeverity severity = VitalTrendSeverity.info,
  int day = 1,
}) {
  return VitalTrendPointDto(
    recordedAt: DateTime.utc(2026, 9, day),
    value: value,
    minimum: minimum ?? value,
    maximum: maximum ?? value,
    readingCount: 2,
    severity: severity,
  );
}
