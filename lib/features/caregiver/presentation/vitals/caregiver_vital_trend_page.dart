import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/widgets/alera_card.dart';
import '../../data/api/caregiver_vital_trend_api_data_source.dart';
import '../../data/api/dto/vital_trend_dto.dart';
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
        elevation: 0,
        title: Text(
          '${widget.metric.label} Trends',
          style: AleraTypography.pageTitle,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(widget.patientName, style: AleraTypography.sectionTitle),
            const SizedBox(height: 4),
            Text(
              'View ${widget.metric.label.toLowerCase()} changes over time.',
              style: AleraTypography.body.copyWith(
                color: AleraColors.textSecondary,
              ),
            ),
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
                color: AleraColors.textSecondary,
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
        AleraCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  _value(summary.latest, trend.unit),
                  style: AleraTypography.pageTitle.copyWith(fontSize: 32),
                ),
                const SizedBox(height: 2),
                Text(
                  'Latest reading',
                  style: AleraTypography.body.copyWith(
                    color: AleraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),
        AleraCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 18, 14, 8),
            child: VitalTrendChart(trend: trend, metric: metric),
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Average',
                value: _value(summary.average, trend.unit),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                label: 'Low',
                value: _value(summary.minimum, trend.unit),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'High',
                value: _value(summary.maximum, trend.unit),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                label: 'Readings',
                value: '${summary.readingCount}',
              ),
            ),
          ],
        ),

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
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AleraCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AleraTypography.body.copyWith(
                color: AleraColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(value, style: AleraTypography.sectionTitle),
          ],
        ),
      ),
    );
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
