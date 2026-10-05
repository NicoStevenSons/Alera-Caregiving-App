import 'dart:async';

import 'package:alera/features/caregiver/data/api/caregiver_vital_trend_api_data_source.dart';
import 'package:alera/features/caregiver/data/api/dto/vital_trend_dto.dart';
import 'package:alera/features/caregiver/presentation/vitals/caregiver_vital_trend_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows loading while the trend request is pending', (
    tester,
  ) async {
    final completer = Completer<VitalTrendDto>();
    final source = _FakeVitalTrendSource(pending: completer);

    await _pumpPage(tester, source);

    expect(find.byKey(const Key('vital-trend-loading')), findsOneWidget);

    completer.complete(_trend());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('vital-trend-loading')), findsNothing);
  });

  testWidgets('shows API failure and retry action', (tester) async {
    final source = _FakeVitalTrendSource(
      failure: const CaregiverVitalTrendApiFailure('Temporary trend failure'),
    );

    await _pumpPage(tester, source);
    await tester.pumpAndSettle();

    expect(find.text('Temporary trend failure'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('shows explicit empty state for a period with no readings', (
    tester,
  ) async {
    final source = _FakeVitalTrendSource(result: _trend(points: const []));

    await _pumpPage(tester, source);
    await tester.pumpAndSettle();

    expect(find.text('No readings in this period'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);

    // The range dropdown must stay reachable even with no data, so another
    // period can still be tried from an empty state.
    expect(find.byKey(const Key('trend-range-dropdown')), findsOneWidget);
  });

  testWidgets('range selector requests the selected backend range', (
    tester,
  ) async {
    final source = _FakeVitalTrendSource(result: _trend());

    await _pumpPage(tester, source);
    await tester.pumpAndSettle();
    expect(source.ranges, [VitalTrendRange.day]);

    await tester.tap(find.byKey(const Key('trend-range-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7D').last);
    await tester.pumpAndSettle();

    expect(source.ranges, [VitalTrendRange.day, VitalTrendRange.week]);
  });

  testWidgets('renders the stat grid with deterministic period values', (
    tester,
  ) async {
    final source = _FakeVitalTrendSource(result: _trend());

    await _pumpPage(tester, source);
    await tester.pumpAndSettle();

    expect(find.text('80 bpm'), findsOneWidget);
    expect(find.text('90 bpm'), findsOneWidget);
    expect(find.text('130 bpm'), findsOneWidget);
    expect(find.text('55 bpm'), findsOneWidget);
    expect(find.text('Latest'), findsOneWidget);
    expect(find.text('Average'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('Low'), findsOneWidget);
  });

  testWidgets('renders a rule-based trend summary from the period stats', (
    tester,
  ) async {
    final source = _FakeVitalTrendSource(result: _trend());

    await _pumpPage(tester, source);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('trend-summary-card')), findsOneWidget);
    expect(
      find.textContaining('stayed within the normal range for'),
      findsOneWidget,
    );
    expect(find.textContaining('critical period'), findsOneWidget);
    expect(find.textContaining('High was 105 bpm on Sep 1.'), findsOneWidget);
  });

  testWidgets('chart exposes thresholds, severity, tooltip details, and gaps', (
    tester,
  ) async {
    final source = _FakeVitalTrendSource(result: _trend());

    await _pumpPage(tester, source);
    await tester.pumpAndSettle();

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final data = chart.data;

    final range = data.rangeAnnotations.horizontalRangeAnnotations.single;
    expect(range.y1, 60);
    expect(range.y2, 100);

    expect(data.lineBarsData, hasLength(2));

    final firstBar = data.lineBarsData.first;
    expect(
      firstBar.dotData.checkToShowDot(firstBar.spots.first, firstBar),
      isFalse,
    );
    expect(
      firstBar.dotData.checkToShowDot(firstBar.spots.last, firstBar),
      isTrue,
    );

    final tooltipItems = data.lineTouchData.touchTooltipData.getTooltipItems([
      LineBarSpot(firstBar, 0, firstBar.spots.last),
    ]);
    final tooltip = tooltipItems.single!.text;

    expect(tooltip, contains('Average: 105 bpm'));
    expect(tooltip, contains('Low: 95'));
    expect(tooltip, contains('High: 115'));
    expect(tooltip, contains('Readings: 2'));
    expect(tooltip, contains('Highest severity: Warning'));
    expect(tooltip, contains('9/1/2026'));
  });

  testWidgets('omits threshold band and explains unconfigured range', (
    tester,
  ) async {
    final source = _FakeVitalTrendSource(
      result: _trend(
        thresholds: const VitalTrendThresholdsDto(
          normalMin: null,
          normalMax: null,
        ),
      ),
    );

    await _pumpPage(tester, source);
    await tester.pumpAndSettle();

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.rangeAnnotations.horizontalRangeAnnotations, isEmpty);
    expect(
      find.textContaining(
        'No custom monitoring range is configured for this patient.',
      ),
      findsOneWidget,
    );
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  CaregiverVitalTrendDataSource source,
) {
  return tester.pumpWidget(
    MaterialApp(
      home: CaregiverVitalTrendPage(
        patientId: 'patient',
        patientName: 'Test Patient',
        metric: VitalTrendMetric.heartRate,
        dataSource: source,
      ),
    ),
  );
}

class _FakeVitalTrendSource implements CaregiverVitalTrendDataSource {
  final VitalTrendDto? result;
  final Object? failure;
  final Completer<VitalTrendDto>? pending;
  final List<VitalTrendRange> ranges = [];

  _FakeVitalTrendSource({this.result, this.failure, this.pending});

  @override
  Future<VitalTrendDto> fetchTrend({
    required String patientId,
    required VitalTrendMetric metric,
    required VitalTrendRange range,
  }) async {
    ranges.add(range);

    if (pending != null) {
      return pending!.future;
    }
    if (failure != null) {
      throw failure!;
    }
    return result ?? _trend();
  }
}

VitalTrendDto _trend({
  List<VitalTrendPointDto>? points,
  VitalTrendThresholdsDto thresholds = const VitalTrendThresholdsDto(
    normalMin: 60,
    normalMax: 100,
  ),
}) {
  final trendPoints =
      points ??
      [
        _point(DateTime.utc(2026, 9, 1), 80, minimum: 75, maximum: 85),
        _point(
          DateTime.utc(2026, 9, 1, 1),
          105,
          minimum: 95,
          maximum: 115,
          severity: VitalTrendSeverity.warning,
        ),
        _point(
          DateTime.utc(2026, 9, 1, 4),
          85,
          minimum: 55,
          maximum: 130,
          severity: VitalTrendSeverity.critical,
        ),
      ];

  return VitalTrendDto(
    patientId: 'patient',
    metricType: 'HEART_RATE',
    unit: 'bpm',
    range: '24h',
    resolution: '1h',
    fromAt: DateTime.utc(2026, 9, 1),
    toAt: DateTime.utc(2026, 9, 2),
    summary: VitalTrendSummaryDto(
      latest: trendPoints.isEmpty ? null : 80,
      average: trendPoints.isEmpty ? null : 90,
      minimum: trendPoints.isEmpty ? null : 55,
      maximum: trendPoints.isEmpty ? null : 130,
      readingCount: trendPoints.isEmpty ? 0 : 6,
    ),
    thresholds: thresholds,
    points: trendPoints,
  );
}

VitalTrendPointDto _point(
  DateTime recordedAt,
  double value, {
  required double minimum,
  required double maximum,
  VitalTrendSeverity severity = VitalTrendSeverity.info,
}) {
  return VitalTrendPointDto(
    recordedAt: recordedAt,
    value: value,
    minimum: minimum,
    maximum: maximum,
    readingCount: 2,
    severity: severity,
  );
}
