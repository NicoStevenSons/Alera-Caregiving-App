import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/widgets/alera_card.dart';
import '../../data/api/caregiver_sleep_trend_api_data_source.dart';
import '../../data/api/dto/sleep_trend_dto.dart';
import 'widgets/sleep_trend_chart.dart';

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
        elevation: 0,
        title: Text('Sleep Trends', style: AleraTypography.pageTitle),
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
              'View recorded sleep duration over time.',
              style: AleraTypography.body.copyWith(
                color: AleraColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _SleepRangeSelector(selected: _range, onSelected: _selectRange),
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
              _SleepTrendContent(trend: _trend!),
          ],
        ),
      ),
    );
  }
}

class _SleepRangeSelector extends StatelessWidget {
  final SleepTrendRange selected;
  final ValueChanged<SleepTrendRange> onSelected;

  const _SleepRangeSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final range in SleepTrendRange.values)
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

class _SleepTrendContent extends StatelessWidget {
  final SleepTrendDto trend;

  const _SleepTrendContent({required this.trend});

  @override
  Widget build(BuildContext context) {
    final summary = trend.summary;

    if (trend.points.isEmpty) {
      return AleraCard(
        key: const Key('sleep-trend-empty'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 30),
          child: Column(
            children: [
              const Icon(
                Icons.bedtime_outlined,
                size: 38,
                color: AleraColors.textSecondary,
              ),
              const SizedBox(height: 10),
              Text(
                'No sleep data in this period',
                style: AleraTypography.sectionTitle,
              ),
              const SizedBox(height: 4),
              Text(
                'Completed sleep durations will appear here when available.',
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
                  _formatPoint(summary.latestNight),
                  key: const Key('sleep-latest-duration'),
                  style: AleraTypography.pageTitle.copyWith(fontSize: 32),
                ),
                const SizedBox(height: 2),
                Text(
                  'Latest recorded sleep',
                  style: AleraTypography.body.copyWith(
                    color: AleraColors.textSecondary,
                  ),
                ),
                if (summary.latestNight != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(summary.latestNight!.activityDate),
                    style: AleraTypography.body.copyWith(
                      color: AleraColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        AleraCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 18, 14, 12),
            child: SleepTrendChart(trend: trend),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SleepSummaryCard(
                label: 'Average',
                value: _formatSeconds(summary.averageDurationSeconds),
                subtitle: 'Per recorded night',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SleepSummaryCard(
                label: 'Nights with data',
                value: '${summary.nightsWithData}',
                subtitle: 'Missing nights excluded',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SleepSummaryCard(
                label: 'Longest',
                value: _formatPoint(summary.longestNight),
                subtitle: _formatDateOrEmpty(
                  summary.longestNight?.activityDate,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SleepSummaryCard(
                label: 'Shortest',
                value: _formatPoint(summary.shortestNight),
                subtitle: _formatDateOrEmpty(
                  summary.shortestNight?.activityDate,
                ),
              ),
            ),
          ],
        ),
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
}

class _SleepSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;

  const _SleepSummaryCard({
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
