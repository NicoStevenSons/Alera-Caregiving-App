import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../data/api/dto/sleep_trend_dto.dart';

class SleepTrendChart extends StatelessWidget {
  final SleepTrendDto trend;

  const SleepTrendChart({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.points.isEmpty) {
      return const SizedBox.shrink();
    }

    final dates = _calendarDates();
    final pointsByDate = {
      for (final point in trend.points) _dateKey(point.activityDate): point,
    };

    final highestHours = trend.points
        .map((point) => point.durationSeconds / 3600)
        .reduce((a, b) => a > b ? a : b);

    final maxY = highestHours <= 0 ? 1.0 : highestHours * 1.15;
    final horizontalInterval = maxY / 4;
    final barWidth = dates.length <= 7 ? 18.0 : 6.0;

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
                    reservedSize: 38,
                    interval: horizontalInterval,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        meta: meta,
                        space: 6,
                        child: Text(
                          '${_formatHoursAxis(value)}h',
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

                      if (index < 0 || index >= dates.length) {
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
                        ? 'No stored sleep data\n${_tooltipDate(date)}'
                        : '${_formatDuration(point.durationSeconds)}\n'
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
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const _SleepChartLegendItem(
          color: Color(0xFF7B61D1),
          label: 'Recorded sleep',
        ),
        const SizedBox(height: 6),
        Text(
          'Nights without completed sleep data are left as gaps.',
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
    required SleepTrendPointDto? point,
    required double width,
  }) {
    final isMissing = point == null;
    final durationHours = isMissing ? 0.0 : point.durationSeconds / 3600;

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: durationHours,
          width: width,
          color: isMissing ? Colors.transparent : const Color(0xFF7B61D1),
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

  String _axisDate(DateTime date) => '${date.month}/${date.day}';

  String _tooltipDate(DateTime date) =>
      '${date.month}/${date.day}/${date.year}';

  String _formatHoursAxis(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
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
}

class _SleepChartLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _SleepChartLegendItem({required this.color, required this.label});

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
