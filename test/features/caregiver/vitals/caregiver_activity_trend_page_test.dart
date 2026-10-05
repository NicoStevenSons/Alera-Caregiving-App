import 'dart:async';

import 'package:alera/features/caregiver/data/api/caregiver_activity_trend_api_data_source.dart';
import 'package:alera/features/caregiver/data/api/dto/activity_trend_dto.dart';
import 'package:alera/features/caregiver/presentation/vitals/caregiver_activity_trend_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows loading while activity request is pending', (
    tester,
  ) async {
    final completer = Completer<ActivityTrendDto>();
    final source = _FakeActivityTrendSource(pending: completer);

    await _pumpPage(tester, source);

    expect(find.byKey(const Key('activity-trend-loading')), findsOneWidget);

    completer.complete(_trend());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('activity-trend-loading')), findsNothing);
  });

  testWidgets('shows API failure and retry action', (tester) async {
    final source = _FakeActivityTrendSource(
      failure: const CaregiverActivityTrendApiFailure(
        'Temporary activity failure',
      ),
    );

    await _pumpPage(tester, source);
    await tester.pumpAndSettle();

    expect(find.text('Temporary activity failure'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byKey(const Key('activity-trend-error')), findsOneWidget);
  });

  testWidgets('shows explicit empty state when no step days exist', (
    tester,
  ) async {
    final source = _FakeActivityTrendSource(result: _trend(points: const []));

    await _pumpPage(tester, source);
    await tester.pumpAndSettle();

    expect(find.text('No activity data in this period'), findsOneWidget);
    expect(find.byKey(const Key('activity-trend-empty')), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);

    // The range dropdown must stay reachable even with no data, so another
    // period can still be tried from an empty state.
    expect(find.byKey(const Key('trend-range-dropdown')), findsOneWidget);
  });

  testWidgets('starts at 7D and requests 30D after range switch', (
    tester,
  ) async {
    final source = _FakeActivityTrendSource(result: _trend());

    await _pumpPage(tester, source);
    await tester.pumpAndSettle();

    expect(source.ranges, [ActivityTrendRange.week]);

    await tester.tap(find.byKey(const Key('trend-range-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30D').last);
    await tester.pumpAndSettle();

    expect(source.ranges, [ActivityTrendRange.week, ActivityTrendRange.month]);
  });

  testWidgets('renders activity summary values', (tester) async {
    final source = _FakeActivityTrendSource(result: _trend());

    await _pumpPage(tester, source);
    await tester.pumpAndSettle();

    expect(find.text('2,667 steps'), findsOneWidget);
    expect(find.text('7,000 steps'), findsOneWidget);
    expect(find.text('0 steps'), findsOneWidget);
    expect(find.text('10/7/2026'), findsOneWidget);
    expect(find.text('10/3/2026'), findsOneWidget);
    expect(find.text('Days with data'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('renders a rule-based trend summary from the period stats', (
    tester,
  ) async {
    final source = _FakeActivityTrendSource(result: _trend());

    await _pumpPage(tester, source);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('trend-summary-card')), findsOneWidget);
    expect(
      find.textContaining(
        'Averaged 2,667 steps per day over 3 recorded days, with a high of '
        '7,000 steps on Oct 7.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('chart keeps calendar gaps and recorded zero distinct', (
    tester,
  ) async {
    final source = _FakeActivityTrendSource(result: _trend());

    await _pumpPage(tester, source);
    await tester.pumpAndSettle();

    final chart = tester.widget<BarChart>(find.byType(BarChart));
    final data = chart.data;

    expect(data.barGroups, hasLength(7));

    final missingGroup = data.barGroups[1];
    final zeroGroup = data.barGroups[2];

    expect(missingGroup.barRods.single.color, Colors.transparent);
    expect(missingGroup.barRods.single.toY, 0);

    expect(zeroGroup.barRods.single.color, const Color(0xFF77A83B));
    expect(zeroGroup.barRods.single.toY, greaterThan(0));

    final missingTooltip = data.barTouchData.touchTooltipData.getTooltipItem(
      missingGroup,
      1,
      missingGroup.barRods.single,
      0,
    );

    final zeroTooltip = data.barTouchData.touchTooltipData.getTooltipItem(
      zeroGroup,
      2,
      zeroGroup.barRods.single,
      0,
    );

    expect(missingTooltip!.text, contains('No stored data'));
    expect(missingTooltip.text, contains('10/2/2026'));
    expect(zeroTooltip!.text, contains('0 steps'));
    expect(zeroTooltip.text, contains('10/3/2026'));
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  CaregiverActivityTrendDataSource source,
) {
  return tester.pumpWidget(
    MaterialApp(
      home: CaregiverActivityTrendPage(
        patientId: 'patient',
        patientName: 'Test Patient',
        dataSource: source,
      ),
    ),
  );
}

class _FakeActivityTrendSource implements CaregiverActivityTrendDataSource {
  final ActivityTrendDto? result;
  final Object? failure;
  final Completer<ActivityTrendDto>? pending;
  final List<ActivityTrendRange> ranges = [];

  _FakeActivityTrendSource({this.result, this.failure, this.pending});

  @override
  Future<ActivityTrendDto> fetchTrend({
    required String patientId,
    required ActivityTrendRange range,
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

ActivityTrendDto _trend({List<ActivityTrendPointDto>? points}) {
  final trendPoints =
      points ??
      [
        ActivityTrendPointDto(
          activityDate: DateTime(2026, 10, 1),
          totalSteps: 1000,
        ),
        ActivityTrendPointDto(
          activityDate: DateTime(2026, 10, 3),
          totalSteps: 0,
        ),
        ActivityTrendPointDto(
          activityDate: DateTime(2026, 10, 7),
          totalSteps: 7000,
        ),
      ];

  final hasPoints = trendPoints.isNotEmpty;

  return ActivityTrendDto(
    patientId: 'patient',
    range: '7d',
    fromDate: DateTime(2026, 10, 1),
    toDate: DateTime(2026, 10, 7),
    summary: ActivityTrendSummaryDto(
      averageStepsPerDay: hasPoints ? 2666.67 : null,
      highestDay: hasPoints ? trendPoints.last : null,
      lowestDay: hasPoints ? trendPoints[1] : null,
      daysWithData: trendPoints.length,
    ),
    points: trendPoints,
  );
}
