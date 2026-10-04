import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../data/api/dto/activity_trend_dto.dart';

class ActivityTrendChart extends StatelessWidget {
  final ActivityTrendDto trend;

  const ActivityTrendChart({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.points.isEmpty) {
      return const SizedBox.shrink();
    }

    final dates = _calendarDates();
    final pointsByDate = {
      for (final point in trend.points) _dateKey(point.activityDate): point,
    };

    final highestSteps = trend.points
        .map((point) => point.totalSteps)
        .reduce((a, b) => a > b ? a : b);

    final maxY = highestSteps == 0 ? 100.0 : highestSteps * 1.15;
    final horizontalInterval = maxY / 4;
    final barWidth = dates.length <= 7 ? 18.0 : 6.0;
    final zeroMarkerHeight = maxY * 0.015;

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: horizontalInterval,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.black.withValues(alpha: 0.06),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    interval: horizontalInterval,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        meta: meta,
                        space: 6,
                        child: Text(
                          _compactSteps(value),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF8E8895),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: dates.length <= 7 ? 1 : 5,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();

                      if (index < 0 ||
                          index >= dates.length ||
                          !_showBottomLabel(index, dates.length)) {
                        return const SizedBox.shrink();
                      }

                      return SideTitleWidget(
                        meta: meta,
                        space: 8,
                        child: Text(
                          _axisDate(dates[index]),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF8E8895),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final date = dates[group.x];
                    final point = pointsByDate[_dateKey(date)];

                    final text = point == null
                        ? 'No stored data\n${_tooltipDate(date)}'
                        : '${point.totalSteps} steps\n'
                              '${_tooltipDate(date)}';

                    return BarTooltipItem(
                      text,
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    );
                  },
                ),
              ),
              barGroups: [
                for (var index = 0; index < dates.length; index++)
                  _barGroup(
                    index: index,
                    point: pointsByDate[_dateKey(dates[index])],
                    width: barWidth,
                    zeroMarkerHeight: zeroMarkerHeight,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const _ChartLegendItem(
          color: Color(0xFF77A83B),
          label: 'Recorded steps',
        ),
        const SizedBox(height: 6),
        Text(
          'Missing days are left as gaps. '
          'A recorded zero remains valid data.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.52),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  BarChartGroupData _barGroup({
    required int index,
    required ActivityTrendPointDto? point,
    required double width,
    required double zeroMarkerHeight,
  }) {
    final isMissing = point == null;

    final displayValue = isMissing
        ? 0.0
        : point.totalSteps == 0
        ? zeroMarkerHeight
        : point.totalSteps.toDouble();

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: displayValue,
          width: width,
          color: isMissing ? Colors.transparent : const Color(0xFF77A83B),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
        ),
      ],
    );
  }

  List<DateTime> _calendarDates() {
    final start = DateTime(
      trend.fromDate.year,
      trend.fromDate.month,
      trend.fromDate.day,
    );

    final end = DateTime(
      trend.toDate.year,
      trend.toDate.month,
      trend.toDate.day,
    );

    final dates = <DateTime>[];
    var current = start;

    while (!current.isAfter(end)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  bool _showBottomLabel(int index, int totalDates) {
    if (totalDates <= 7) {
      return true;
    }

    // Keep the first and last dates, with roughly weekly labels between them.
    return index == 0 || index == totalDates - 1 || index % 6 == 0;
  }

  String _axisDate(DateTime date) => '${date.month}/${date.day}';

  String _tooltipDate(DateTime date) =>
      '${date.month}/${date.day}/${date.year}';

  String _compactSteps(double value) {
    if (value >= 1000) {
      final compact = value / 1000;

      return compact % 1 == 0
          ? '${compact.toStringAsFixed(0)}k'
          : '${compact.toStringAsFixed(1)}k';
    }

    return value.toStringAsFixed(0);
  }
}

class _ChartLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF756E80), fontSize: 11),
        ),
      ],
    );
  }
}
