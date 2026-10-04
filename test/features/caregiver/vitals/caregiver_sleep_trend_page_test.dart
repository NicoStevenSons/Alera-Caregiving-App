import 'dart:async';

import 'package:alera/features/caregiver/data/api/caregiver_sleep_trend_api_data_source.dart';
import 'package:alera/features/caregiver/data/api/dto/sleep_trend_dto.dart';
import 'package:alera/features/caregiver/presentation/vitals/caregiver_sleep_trend_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows loading while the sleep request is pending', (
    tester,
  ) async {
    final completer = Completer<SleepTrendDto>();
    final source = _FakeSleepTrendSource(pending: completer);

    await _pumpPage(tester, source);

    expect(find.byKey(const Key('sleep-trend-loading')), findsOneWidget);

    completer.complete(_trend());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sleep-trend-loading')), findsNothing);
  });

  testWidgets('shows API failure and retries the request', (tester) async {
    final source = _FakeSleepTrendSource(
      failure: const CaregiverSleepTrendApiFailure(
        'Temporary sleep trend failure',
      ),
    );

    await _pumpPage(tester, source);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sleep-trend-error')), findsOneWidget);
    expect(find.text('Temporary sleep trend failure'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(source.ranges, [SleepTrendRange.week, SleepTrendRange.week]);
  });

  testWidgets('shows explicit empty state when no sleep data exists', (
    tester,
  ) async {
    final source = _FakeSleepTrendSource(result: _trend(points: const []));

    await _pumpPage(tester, source);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sleep-trend-empty')), findsOneWidget);
    expect(find.text('No sleep data in this period'), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
  });

  testWidgets('defaults to 7D and requests 30D when selected', (tester) async {
    final source = _FakeSleepTrendSource(result: _trend());

    await _pumpPage(tester, source);
    await tester.pumpAndSettle();

    expect(source.ranges, [SleepTrendRange.week]);

    await tester.tap(find.text('30D'));
    await tester.pumpAndSettle();

    expect(source.ranges, [SleepTrendRange.week, SleepTrendRange.month]);
  });

  testWidgets('renders recorded sleep summary values', (tester) async {
    final source = _FakeSleepTrendSource(result: _trend());

    await _pumpPage(tester, source);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sleep-latest-duration')), findsOneWidget);
    expect(find.text('8h'), findsWidgets);
    expect(find.text('7h 10m'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('6h'), findsOneWidget);
    expect(find.text('Average'), findsOneWidget);
    expect(find.text('Nights with data'), findsOneWidget);
    expect(find.text('Longest'), findsOneWidget);
    expect(find.text('Shortest'), findsOneWidget);
  });

  testWidgets('chart preserves calendar gaps and exposes tooltips', (
    tester,
  ) async {
    final source = _FakeSleepTrendSource(result: _trend());

    await _pumpPage(tester, source);
    await tester.pumpAndSettle();

    final chart = tester.widget<BarChart>(find.byType(BarChart));
    final data = chart.data;

    expect(data.barGroups, hasLength(7));

    final recordedGroup = data.barGroups[0];
    final missingGroup = data.barGroups[1];

    expect(recordedGroup.barRods.single.toY, 6);
    expect(recordedGroup.barRods.single.color, const Color(0xFF7B61D1));

    expect(missingGroup.barRods.single.toY, 0);
    expect(missingGroup.barRods.single.color, Colors.transparent);

    final tooltipBuilder = data.barTouchData.touchTooltipData.getTooltipItem;

    final recordedTooltip = tooltipBuilder(
      recordedGroup,
      0,
      recordedGroup.barRods.single,
      0,
    );

    expect(recordedTooltip?.text, contains('6h'));
    expect(recordedTooltip?.text, contains('10/1/2026'));

    final missingTooltip = tooltipBuilder(
      missingGroup,
      1,
      missingGroup.barRods.single,
      0,
    );

    expect(missingTooltip?.text, contains('No stored sleep data'));
    expect(missingTooltip?.text, contains('10/2/2026'));
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  CaregiverSleepTrendDataSource source,
) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      home: CaregiverSleepTrendPage(
        patientId: 'patient',
        patientName: 'Test Patient',
        dataSource: source,
      ),
    ),
  );
}

class _FakeSleepTrendSource implements CaregiverSleepTrendDataSource {
  final SleepTrendDto? result;
  final Object? failure;
  final Completer<SleepTrendDto>? pending;
  final List<SleepTrendRange> ranges = [];

  _FakeSleepTrendSource({this.result, this.failure, this.pending});

  @override
  Future<SleepTrendDto> fetchTrend({
    required String patientId,
    required SleepTrendRange range,
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

SleepTrendDto _trend({List<SleepTrendPointDto>? points}) {
  final trendPoints =
      points ??
      [
        _point(DateTime(2026, 10, 1), 6 * 3600),
        _point(DateTime(2026, 10, 3), 7 * 3600 + 30 * 60),
        _point(DateTime(2026, 10, 7), 8 * 3600),
      ];

  final isEmpty = trendPoints.isEmpty;

  return SleepTrendDto(
    patientId: 'patient',
    range: '7d',
    fromDate: DateTime(2026, 10, 1),
    toDate: DateTime(2026, 10, 7),
    summary: SleepTrendSummaryDto(
      latestNight: isEmpty ? null : trendPoints.last,
      averageDurationSeconds: isEmpty ? null : 7 * 3600 + 10 * 60,
      longestNight: isEmpty ? null : trendPoints.last,
      shortestNight: isEmpty ? null : trendPoints.first,
      nightsWithData: trendPoints.length,
    ),
    points: trendPoints,
  );
}

SleepTrendPointDto _point(DateTime activityDate, int durationSeconds) {
  return SleepTrendPointDto(
    activityDate: activityDate,
    durationSeconds: durationSeconds,
  );
}
