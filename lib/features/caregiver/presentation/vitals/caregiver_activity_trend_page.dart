import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/widgets/alera_card.dart';
import '../../../../design_system/widgets/alera_svg_icon.dart';
import '../../data/api/caregiver_activity_trend_api_data_source.dart';
import '../../data/api/dto/activity_trend_dto.dart';
import 'widgets/activity_trend_chart.dart';
import 'widgets/trend_date_format.dart';
import 'widgets/trend_summary_card.dart';
import 'widgets/vital_stat_grid.dart';
import 'widgets/vital_trend_metric_pills.dart';
import 'widgets/vital_trend_navigation.dart';
import 'widgets/vital_trend_range_header.dart';

class CaregiverActivityTrendPage extends StatefulWidget {
  final String patientId;
  final String patientName;
  final CaregiverActivityTrendDataSource dataSource;

  const CaregiverActivityTrendPage({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.dataSource,
  });

  @override
  State<CaregiverActivityTrendPage> createState() =>
      _CaregiverActivityTrendPageState();
}

class _CaregiverActivityTrendPageState
    extends State<CaregiverActivityTrendPage> {
  ActivityTrendRange _range = ActivityTrendRange.week;

  ActivityTrendDto? _trend;
  Object? _error;

  bool _loading = true;
  int _requestRevision = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final revision = ++_requestRevision;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final trend = await widget.dataSource.fetchTrend(
        patientId: widget.patientId,
        range: _range,
      );

      if (!mounted || revision != _requestRevision) {
        return;
      }

      setState(() {
        _trend = trend;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || revision != _requestRevision) {
        return;
      }

      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _selectRange(ActivityTrendRange range) {
    if (_range == range) {
      return;
    }

    setState(() {
      _range = range;
    });

    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 44,
        leadingWidth: 56,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.chevron_left, size: 28),
          color: const Color(0xFFB4AEC2),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            Text('Activity', style: AleraTypography.sectionTitle),
            const SizedBox(height: 12),

            VitalTrendMetricPills(
              selected: 'Activity',
              onSelected: (metric) => switchVitalTrendPage(
                context,
                metric: metric,
                patientId: widget.patientId,
                patientName: widget.patientName,
              ),
              onUnavailable: (metric) =>
                  showVitalTrendUnavailable(context, metric),
            ),

            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                key: Key('activity-trend-loading'),
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _ActivityTrendError(error: _error!, onRetry: _load)
            else if (_trend != null)
              _ActivityTrendContent(
                trend: _trend!,
                range: _range,
                onRangeSelected: (label) {
                  final range = ActivityTrendRange.values.firstWhere(
                    (candidate) => candidate.label == label,
                  );
                  _selectRange(range);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTrendContent extends StatelessWidget {
  final ActivityTrendDto trend;
  final ActivityTrendRange range;
  final ValueChanged<String> onRangeSelected;

  const _ActivityTrendContent({
    required this.trend,
    required this.range,
    required this.onRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final summary = trend.summary;

    if (trend.points.isEmpty) {
      return AleraCard(
        key: const Key('activity-trend-empty'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 30),
          child: Column(
            children: [
              const Icon(
                Icons.directions_walk_outlined,
                size: 38,
                color: AleraColors.primary,
              ),
              const SizedBox(height: 10),
              Text(
                'No activity data in this period',
                style: AleraTypography.sectionTitle,
              ),
              const SizedBox(height: 4),
              Text(
                'Recorded step totals will appear here when available.',
                textAlign: TextAlign.center,
                style: AleraTypography.body.copyWith(
                  color: AleraColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        VitalStatGrid(
          tiles: [
            VitalStatTile(
              label: 'Average',
              value: _formatAverage(summary.averageStepsPerDay),
              subtitle: 'per day',
              icon: const AleraSvgIcon(
                assetPath:
                    'alera-figma-assets/assets/icons/mini_status/activity.svg',
                width: 36,
                height: 36,
              ),
            ),
            VitalStatTile(
              label: 'Highest',
              value: _formatPoint(summary.highestDay),
              subtitle: _formatDate(summary.highestDay?.activityDate),
              icon: const VitalStatAssetIcon(
                assetPath:
                    'alera-figma-assets/assets/icons/mini_status/'
                    'stat_high.svg',
              ),
            ),
            VitalStatTile(
              label: 'Lowest',
              value: _formatPoint(summary.lowestDay),
              subtitle: _formatDate(summary.lowestDay?.activityDate),
              icon: const VitalStatAssetIcon(
                assetPath:
                    'alera-figma-assets/assets/icons/mini_status/stat_low.svg',
              ),
            ),
            VitalStatTile(
              label: 'Days with data',
              value: '${summary.daysWithData}',
              icon: const VitalStatAssetIcon(
                assetPath:
                    'alera-figma-assets/assets/icons/mini_status/'
                    'stat_average.svg',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AleraCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VitalTrendRangeHeader(
                  title: 'Activity Trend',
                  fromDate: trend.fromDate,
                  toDate: trend.toDate,
                  selectedLabel: range.label,
                  rangeLabels: [
                    for (final value in ActivityTrendRange.values)
                      value.label,
                  ],
                  onRangeSelected: onRangeSelected,
                ),
                const SizedBox(height: 10),
                ActivityTrendChart(trend: trend),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TrendSummaryCard(text: _trendSummaryText(trend)),
        const SizedBox(height: 12),
      ],
    );
  }

  String _formatAverage(double? value) {
    if (value == null) {
      return '—';
    }

    final rounded = value.round();
    return '${_withThousands(rounded)} steps';
  }

  String _formatPoint(ActivityTrendPointDto? point) {
    if (point == null) {
      return '—';
    }

    return '${_withThousands(point.totalSteps)} steps';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    return '${date.month}/${date.day}/${date.year}';
  }

  String _withThousands(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
  }

  /// Computed locally from the same period stats shown in the grid above -
  /// not model-generated. Swap this for a real AI-written summary once a
  /// backend endpoint for it exists; nothing else on the page needs to
  /// change.
  String _trendSummaryText(ActivityTrendDto trend) {
    final summary = trend.summary;
    if (trend.points.isEmpty) {
      return 'No step data recorded for this period yet.';
    }

    final days = summary.daysWithData;
    final buffer = StringBuffer();

    if (summary.averageStepsPerDay != null) {
      buffer.write(
        'Averaged ${_withThousands(summary.averageStepsPerDay!.round())} '
        'steps per day over $days recorded day${days == 1 ? '' : 's'}',
      );
    } else {
      buffer.write('$days recorded day${days == 1 ? '' : 's'} with step data');
    }

    final high = summary.highestDay;
    if (high != null) {
      buffer.write(
        ', with a high of ${_withThousands(high.totalSteps)} steps on '
        '${formatTrendShortDate(high.activityDate)}.',
      );
    } else {
      buffer.write('.');
    }

    return buffer.toString();
  }
}

class _ActivityTrendError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ActivityTrendError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final message = error is CaregiverActivityTrendApiFailure
        ? (error as CaregiverActivityTrendApiFailure).message
        : 'Unable to load activity trends.';

    return AleraCard(
      key: const Key('activity-trend-error'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 36),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
