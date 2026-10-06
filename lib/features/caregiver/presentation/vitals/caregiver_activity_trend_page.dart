import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/widgets/alera_card.dart';
import '../../data/api/caregiver_activity_trend_api_data_source.dart';
import '../../data/api/dto/activity_trend_dto.dart';
import 'widgets/activity_trend_chart.dart';
import 'widgets/trend_loading_skeleton.dart';

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
        elevation: 0,
        title: Text('Activity Trends', style: AleraTypography.pageTitle),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text(widget.patientName, style: AleraTypography.sectionTitle),
            const SizedBox(height: 4),
            Text(
              'View daily step totals over time.',
              style: AleraTypography.body.copyWith(
                color: AleraColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _ActivityRangeSelector(selected: _range, onSelected: _selectRange),
            const SizedBox(height: 16),
            if (_loading)
              const TrendLoadingSkeleton(key: Key('activity-trend-loading'))
            else if (_error != null)
              _ActivityTrendError(error: _error!, onRetry: _load)
            else if (_trend != null)
              _ActivityTrendContent(trend: _trend!),
          ],
        ),
      ),
    );
  }
}

class _ActivityRangeSelector extends StatelessWidget {
  final ActivityTrendRange selected;
  final ValueChanged<ActivityTrendRange> onSelected;

  const _ActivityRangeSelector({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final range in ActivityTrendRange.values)
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
    );
  }
}

class _ActivityTrendContent extends StatelessWidget {
  final ActivityTrendDto trend;

  const _ActivityTrendContent({required this.trend});

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
                color: AleraColors.textSecondary,
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
        AleraCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  _formatAverage(summary.averageStepsPerDay),
                  key: const Key('activity-average-steps'),
                  style: AleraTypography.pageTitle.copyWith(fontSize: 32),
                ),
                const SizedBox(height: 2),
                Text(
                  'Average steps per recorded day',
                  textAlign: TextAlign.center,
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
            padding: const EdgeInsets.fromLTRB(10, 18, 14, 12),
            child: ActivityTrendChart(trend: trend),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActivitySummaryCard(
                label: 'Highest day',
                value: _formatPoint(summary.highestDay),
                subtitle: _formatDate(summary.highestDay?.activityDate),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActivitySummaryCard(
                label: 'Lowest day',
                value: _formatPoint(summary.lowestDay),
                subtitle: _formatDate(summary.lowestDay?.activityDate),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ActivitySummaryCard(
          label: 'Days with data',
          value: '${summary.daysWithData}',
          subtitle: 'Missing days are not counted as zero.',
        ),
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
}

class _ActivitySummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;

  const _ActivitySummaryCard({
    required this.label,
    required this.value,
    required this.subtitle,
  });

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
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AleraTypography.body.copyWith(
                  color: AleraColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
