import 'package:flutter/material.dart';

import '../../../../design_system/widgets/alera_card.dart';
import '../../../../design_system/widgets/alera_svg_icon.dart';
import '../../data/api/caregiver_vital_trend_api_data_source.dart';
import '../../data/api/dto/vital_trend_dto.dart';
import '../../domain/vital_trend_period_analytics.dart';
import 'widgets/trend_chart_empty_state.dart';
import 'widgets/trend_date_format.dart';
import 'widgets/trend_loading_skeleton.dart';
import 'widgets/trend_summary_card.dart';
import 'widgets/vital_stat_grid.dart';
import 'widgets/vital_trend_chart.dart';
import 'widgets/vital_trend_metric_pills.dart';
import 'widgets/vital_trend_navigation.dart';
import 'widgets/vital_trend_range_header.dart';

class CaregiverVitalTrendPage extends StatefulWidget {
  final String patientId;
  final String patientName;
  final VitalTrendMetric metric;
  final CaregiverVitalTrendDataSource dataSource;

  const CaregiverVitalTrendPage({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.metric,
    required this.dataSource,
  });

  @override
  State<CaregiverVitalTrendPage> createState() =>
      _CaregiverVitalTrendPageState();
}

class _CaregiverVitalTrendPageState extends State<CaregiverVitalTrendPage> {
  VitalTrendRange _range = VitalTrendRange.day;

  VitalTrendDto? _trend;
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
        metric: widget.metric,
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

  void _selectRange(VitalTrendRange range) {
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            VitalTrendMetricPills(
              selected: widget.metric.label,
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
              const TrendLoadingSkeleton(key: Key('vital-trend-loading'))
            else if (_error != null)
              _TrendError(error: _error!, onRetry: _load)
            else if (_trend != null)
              _TrendContent(
                trend: _trend!,
                metric: widget.metric,
                range: _range,
                onRangeSelected: (label) {
                  final range = VitalTrendRange.values.firstWhere(
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

class _TrendContent extends StatelessWidget {
  final VitalTrendDto trend;
  final VitalTrendMetric metric;
  final VitalTrendRange range;
  final ValueChanged<String> onRangeSelected;

  const _TrendContent({
    required this.trend,
    required this.metric,
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
              value: _value(summary.latest, trend.unit),
              icon: AleraSvgIcon(
                assetPath: _metricIconAsset(metric),
                width: 36,
                height: 36,
              ),
            ),
            VitalStatTile(
              label: 'Average',
              value: _value(summary.average, trend.unit),
              icon: const VitalStatAssetIcon(
                assetPath:
                    'alera-figma-assets/assets/icons/mini_status/'
                    'stat_average.svg',
              ),
            ),
            VitalStatTile(
              label: 'High',
              value: _value(summary.maximum, trend.unit),
              icon: const VitalStatAssetIcon(
                assetPath:
                    'alera-figma-assets/assets/icons/mini_status/'
                    'stat_high.svg',
              ),
            ),
            VitalStatTile(
              label: 'Low',
              value: _value(summary.minimum, trend.unit),
              icon: const VitalStatAssetIcon(
                assetPath:
                    'alera-figma-assets/assets/icons/mini_status/stat_low.svg',
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        AleraCard(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VitalTrendRangeHeader(
                title: '${metric.label} Trend',
                fromDate: trend.fromAt,
                toDate: trend.toAt,
                selectedLabel: range.label,
                rangeLabels: [
                  for (final value in VitalTrendRange.values) value.label,
                ],
                onRangeSelected: onRangeSelected,
              ),
              const SizedBox(height: 10),
              if (hasData)
                VitalTrendChart(trend: trend, metric: metric)
              else
                const TrendChartEmptyState(
                  message:
                      'Try a different range above, or check back once '
                      'new readings come in.',
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        TrendSummaryCard(text: _trendSummaryText(trend)),

        const SizedBox(height: 12),
      ],
    );
  }

  String _value(double? value, String unit) {
    if (value == null) {
      return '—';
    }

    final formatted = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);

    return '$formatted $unit';
  }

  String _metricIconAsset(VitalTrendMetric metric) => switch (metric) {
    VitalTrendMetric.heartRate =>
      'alera-figma-assets/assets/icons/mini_status/heart_rate.svg',
    VitalTrendMetric.spo2 =>
      'alera-figma-assets/assets/icons/mini_status/spo2.svg',
  };

  /// Computed locally from the same period stats shown in the grid above -
  /// not model-generated. Swap this for a real AI-written summary once a
  /// backend endpoint for it exists; nothing else on the page needs to
  /// change.
  String _trendSummaryText(VitalTrendDto trend) {
    final points = trend.points;
    if (points.isEmpty) {
      return 'No readings recorded for this period yet.';
    }

    final analytics = VitalTrendPeriodAnalytics.fromTrend(trend);
    final total = points.length;
    final normal = total - analytics.abnormalPeriodCount;
    final metricLabel = trend.metricType == 'SPO2' ? 'SpO₂' : 'Heart rate';

    final peak = points.reduce((a, b) => a.value > b.value ? a : b);

    final buffer = StringBuffer(
      '$metricLabel stayed within the normal range for $normal of $total '
      'periods',
    );

    if (analytics.criticalPeriodCount > 0) {
      final count = analytics.criticalPeriodCount;
      buffer.write(', with $count critical period${count == 1 ? '' : 's'}');
    } else if (analytics.warningPeriodCount > 0) {
      final count = analytics.warningPeriodCount;
      buffer.write(', with $count elevated period${count == 1 ? '' : 's'}');
    }

    buffer.write(
      '. High was ${_value(peak.value, trend.unit)} on '
      '${formatTrendShortDate(peak.recordedAt)}.',
    );

    if (analytics.outsideConfiguredRangeCount == null) {
      buffer.write(
        ' No custom monitoring range is configured for this patient.',
      );
    }

    return buffer.toString();
  }
}

class _TrendError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _TrendError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final message = error is CaregiverVitalTrendApiFailure
        ? (error as CaregiverVitalTrendApiFailure).message
        : 'Unable to load vital trends.';

    return AleraCard(
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
    );
  }
}
