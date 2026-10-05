import 'package:flutter/material.dart';

import '../../../../design_system/widgets/alera_card.dart';
import '../../../../design_system/widgets/alera_svg_icon.dart';
import '../../data/api/caregiver_sleep_trend_api_data_source.dart';
import '../../data/api/dto/sleep_trend_dto.dart';
import 'widgets/sleep_trend_chart.dart';
import 'widgets/trend_chart_empty_state.dart';
import 'widgets/trend_date_format.dart';
import 'widgets/trend_summary_card.dart';
import 'widgets/vital_stat_grid.dart';
import 'widgets/vital_trend_metric_pills.dart';
import 'widgets/vital_trend_navigation.dart';
import 'widgets/vital_trend_range_header.dart';

class CaregiverSleepTrendPage extends StatefulWidget {
  final String patientId;
  final String patientName;
  final CaregiverSleepTrendDataSource dataSource;

  const CaregiverSleepTrendPage({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.dataSource,
  });

  @override
  State<CaregiverSleepTrendPage> createState() =>
      _CaregiverSleepTrendPageState();
}

class _CaregiverSleepTrendPageState extends State<CaregiverSleepTrendPage> {
  SleepTrendRange _range = SleepTrendRange.week;

  SleepTrendDto? _trend;
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

  void _selectRange(SleepTrendRange range) {
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
            VitalTrendMetricPills(
              selected: 'Sleep',
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
                key: Key('sleep-trend-loading'),
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _SleepTrendError(error: _error!, onRetry: _load)
            else if (_trend != null)
              _SleepTrendContent(
                trend: _trend!,
                range: _range,
                onRangeSelected: (label) {
                  final range = SleepTrendRange.values.firstWhere(
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

class _SleepTrendContent extends StatelessWidget {
  final SleepTrendDto trend;
  final SleepTrendRange range;
  final ValueChanged<String> onRangeSelected;

  const _SleepTrendContent({
    required this.trend,
    required this.range,
    required this.onRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final summary = trend.summary;
    final hasData = trend.points.isNotEmpty;

    return Column(
      children: [
        VitalStatGrid(
          tiles: [
            VitalStatTile(
              label: 'Latest',
              value: _formatPoint(summary.latestNight),
              valueKey: const Key('sleep-latest-duration'),
              subtitle: summary.latestNight == null
                  ? null
                  : _formatDate(summary.latestNight!.activityDate),
              icon: const AleraSvgIcon(
                assetPath:
                    'alera-figma-assets/assets/icons/mini_status/sleep.svg',
                width: 36,
                height: 36,
              ),
            ),
            VitalStatTile(
              label: 'Average',
              value: _formatSeconds(summary.averageDurationSeconds),
              subtitle: 'per night',
              icon: const VitalStatAssetIcon(
                assetPath:
                    'alera-figma-assets/assets/icons/mini_status/'
                    'stat_average.svg',
              ),
            ),
            VitalStatTile(
              label: 'Longest',
              value: _formatPoint(summary.longestNight),
              subtitle: _formatDateOrEmpty(summary.longestNight?.activityDate),
              icon: const VitalStatAssetIcon(
                assetPath:
                    'alera-figma-assets/assets/icons/mini_status/'
                    'stat_high.svg',
              ),
            ),
            VitalStatTile(
              label: 'Shortest',
              value: _formatPoint(summary.shortestNight),
              subtitle: _formatDateOrEmpty(
                summary.shortestNight?.activityDate,
              ),
              icon: const VitalStatAssetIcon(
                assetPath:
                    'alera-figma-assets/assets/icons/mini_status/stat_low.svg',
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
                  title: 'Sleep Trend',
                  fromDate: trend.fromDate,
                  toDate: trend.toDate,
                  selectedLabel: range.label,
                  rangeLabels: [
                    for (final value in SleepTrendRange.values) value.label,
                  ],
                  onRangeSelected: onRangeSelected,
                ),
                const SizedBox(height: 10),
                if (hasData)
                  SleepTrendChart(trend: trend)
                else
                  const TrendChartEmptyState(
                    key: Key('sleep-trend-empty'),
                    title: 'No sleep data in this period',
                    message:
                        'Try a different range above, or check back once '
                        'new sleep data comes in.',
                  ),
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

  String _formatPoint(SleepTrendPointDto? point) {
    if (point == null) {
      return '—';
    }

    return _formatSeconds(point.durationSeconds.toDouble());
  }

  String _formatSeconds(double? seconds) {
    if (seconds == null) {
      return '—';
    }

    final duration = Duration(seconds: seconds.round());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    }

    if (hours > 0) {
      return '${hours}h';
    }

    return '${minutes}m';
  }

  String _formatDateOrEmpty(DateTime? date) {
    if (date == null) {
      return '';
    }

    return _formatDate(date);
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  /// Computed locally from the same period stats shown in the grid above -
  /// not model-generated. Swap this for a real AI-written summary once a
  /// backend endpoint for it exists; nothing else on the page needs to
  /// change.
  String _trendSummaryText(SleepTrendDto trend) {
    final summary = trend.summary;
    if (trend.points.isEmpty) {
      return 'No sleep data recorded for this period yet.';
    }

    final nights = summary.nightsWithData;
    final buffer = StringBuffer(
      'Averaged ${_formatSeconds(summary.averageDurationSeconds)} of sleep '
      'per night over $nights recorded night${nights == 1 ? '' : 's'}',
    );

    final longest = summary.longestNight;
    if (longest != null) {
      buffer.write(
        ', with the longest at '
        '${_formatSeconds(longest.durationSeconds.toDouble())} on '
        '${formatTrendShortDate(longest.activityDate)}.',
      );
    } else {
      buffer.write('.');
    }

    return buffer.toString();
  }
}

class _SleepTrendError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _SleepTrendError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final message = error is CaregiverSleepTrendApiFailure
        ? (error as CaregiverSleepTrendApiFailure).message
        : 'Unable to load sleep trends.';

    return AleraCard(
      key: const Key('sleep-trend-error'),
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
