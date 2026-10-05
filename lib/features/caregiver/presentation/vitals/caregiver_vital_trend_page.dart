import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/widgets/alera_card.dart';
import '../../../../design_system/widgets/alera_svg_icon.dart';
import '../../data/api/caregiver_vital_trend_api_data_source.dart';
import '../../data/api/dto/vital_trend_dto.dart';
import '../../domain/vital_trend_period_analytics.dart';
import 'widgets/trend_date_format.dart';
import 'widgets/trend_summary_card.dart';
import 'widgets/vital_stat_grid.dart';
import 'widgets/vital_trend_chart.dart';

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
            Text(widget.metric.label, style: AleraTypography.sectionTitle),
            const SizedBox(height: 16),

            _RangeSelector(selected: _range, onSelected: _selectRange),

            const SizedBox(height: 16),

            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _TrendError(error: _error!, onRetry: _load)
            else if (_trend != null)
              _TrendContent(trend: _trend!, metric: widget.metric),
          ],
        ),
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  final VitalTrendRange selected;
  final ValueChanged<VitalTrendRange> onSelected;

  const _RangeSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final range in VitalTrendRange.values) ...[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ChoiceChip(
                label: SizedBox(
                  width: double.infinity,
                  child: Text(range.label, textAlign: TextAlign.center),
                ),
                selected: selected == range,
                onSelected: (_) => onSelected(range),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TrendContent extends StatelessWidget {
  final VitalTrendDto trend;
  final VitalTrendMetric metric;

  const _TrendContent({required this.trend, required this.metric});

  @override
  Widget build(BuildContext context) {
    final summary = trend.summary;

    if (summary.readingCount == 0) {
      return AleraCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 30),
          child: Column(
            children: [
              const Icon(
                Icons.show_chart,
                size: 38,
                color: AleraColors.primary,
              ),
              const SizedBox(height: 10),
              Text(
                'No readings in this period',
                style: AleraTypography.sectionTitle,
              ),
              const SizedBox(height: 4),
              Text(
                'New readings will appear here when they become available.',
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
              icon: const VitalStatIconBadge(
                icon: Icons.bar_chart_rounded,
                color: AleraColors.primary,
              ),
            ),
            VitalStatTile(
              label: 'High',
              value: _value(summary.maximum, trend.unit),
              icon: const VitalStatIconBadge(
                icon: Icons.arrow_upward_rounded,
                color: AleraColors.critical,
              ),
            ),
            VitalStatTile(
              label: 'Low',
              value: _value(summary.minimum, trend.unit),
              icon: const VitalStatIconBadge(
                icon: Icons.arrow_downward_rounded,
                color: AleraColors.information,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        AleraCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 18, 14, 8),
            child: VitalTrendChart(trend: trend, metric: metric),
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
