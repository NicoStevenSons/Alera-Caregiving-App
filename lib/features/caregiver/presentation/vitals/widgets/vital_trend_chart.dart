import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../data/api/dto/vital_trend_dto.dart';

class VitalTrendChart extends StatelessWidget {
  final VitalTrendDto trend;
  final VitalTrendMetric metric;

  const VitalTrendChart({super.key, required this.trend, required this.metric});

  @override
  Widget build(BuildContext context) {
    if (trend.points.isEmpty) {
      return const SizedBox.shrink();
    }

    final lineColor = switch (metric) {
      VitalTrendMetric.heartRate => const Color(0xFFFF7192),
      VitalTrendMetric.spo2 => const Color(0xFF9378F1),
    };

    final segments = _segments();

    final values = trend.points
        .expand((point) => [point.minimum, point.maximum])
        .toList();

    double minY = values.reduce((a, b) => a < b ? a : b);
    double maxY = values.reduce((a, b) => a > b ? a : b);

    final padding = metric == VitalTrendMetric.heartRate ? 10.0 : 2.0;

    minY -= padding;
    maxY += padding;

    if (metric == VitalTrendMetric.spo2) {
      minY = minY.clamp(0, 100).toDouble();
      maxY = maxY.clamp(0, 100).toDouble();
    }

    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: _xFor(trend.toAt),
          minY: minY,
          maxY: maxY,

          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: metric == VitalTrendMetric.heartRate ? 20 : 2,
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
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    meta: meta,
                    space: 6,
                    child: Text(
                      value.toStringAsFixed(0),
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
                interval: _bottomInterval(),
                getTitlesWidget: (value, meta) {
                  final time = trend.fromAt.add(
                    Duration(milliseconds: (value * 1000).round()),
                  );

                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(
                      _axisLabel(time),
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

          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final recordedAt = trend.fromAt.add(
                    Duration(milliseconds: (spot.x * 1000).round()),
                  );

                  final value = spot.y % 1 == 0
                      ? spot.y.toStringAsFixed(0)
                      : spot.y.toStringAsFixed(1);

                  return LineTooltipItem(
                    '$value ${trend.unit}\n${_tooltipTime(recordedAt)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),

          lineBarsData: [
            for (final segment in segments)
              LineChartBarData(
                spots: segment
                    .map(
                      (point) => FlSpot(_xFor(point.recordedAt), point.value),
                    )
                    .toList(),
                isCurved: true,
                preventCurveOverShooting: true,
                color: lineColor,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(show: segment.length == 1),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      lineColor.withValues(alpha: 0.20),
                      lineColor.withValues(alpha: 0.01),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _xFor(DateTime time) {
    return time.difference(trend.fromAt).inMilliseconds / 1000;
  }

  double _bottomInterval() {
    return switch (trend.range) {
      '24h' => const Duration(hours: 6).inSeconds.toDouble(),
      '7d' => const Duration(days: 2).inSeconds.toDouble(),
      '30d' => const Duration(days: 7).inSeconds.toDouble(),
      _ => const Duration(hours: 6).inSeconds.toDouble(),
    };
  }

  String _axisLabel(DateTime value) {
    final local = value.toLocal();

    return switch (trend.range) {
      '24h' => '${local.hour.toString().padLeft(2, '0')}:00',

      '7d' || '30d' => '${local.month}/${local.day}',

      _ => '${local.month}/${local.day}',
    };
  }

  String _tooltipTime(DateTime value) {
    final local = value.toLocal();

    if (trend.range == '24h') {
      final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final period = local.hour >= 12 ? 'PM' : 'AM';

      return '${hour.toString()}:'
          '${local.minute.toString().padLeft(2, '0')} $period';
    }

    return '${local.month}/${local.day}/${local.year}';
  }

  List<List<VitalTrendPointDto>> _segments() {
    final points = [...trend.points]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    if (points.isEmpty) {
      return const [];
    }

    final expectedGap = switch (trend.resolution) {
      '1h' => const Duration(hours: 1),
      '1d' => const Duration(days: 1),
      _ => const Duration(hours: 1),
    };

    final maximumContinuousGap = Duration(
      milliseconds: (expectedGap.inMilliseconds * 1.5).round(),
    );

    final segments = <List<VitalTrendPointDto>>[];
    var current = <VitalTrendPointDto>[points.first];

    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final point = points[index];

      final gap = point.recordedAt.difference(previous.recordedAt);

      if (gap > maximumContinuousGap) {
        segments.add(current);
        current = <VitalTrendPointDto>[point];
      } else {
        current.add(point);
      }
    }

    segments.add(current);

    return segments;
  }
}
