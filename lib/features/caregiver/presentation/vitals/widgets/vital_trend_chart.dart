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
    final normalMin = trend.thresholds.normalMin;
    final normalMax = trend.thresholds.normalMax;
    final hasNormalRange =
        normalMin != null && normalMax != null && normalMin <= normalMax;

    final values = trend.points
        .expand((point) => [point.minimum, point.maximum])
        .toList();

    if (hasNormalRange) {
      values
        ..add(normalMin)
        ..add(normalMax);
    }

    double minY = values.reduce((a, b) => a < b ? a : b);
    double maxY = values.reduce((a, b) => a > b ? a : b);

    final padding = metric == VitalTrendMetric.heartRate ? 10.0 : 2.0;

    minY -= padding;
    maxY += padding;

    if (metric == VitalTrendMetric.spo2) {
      minY = minY.clamp(0, 100).toDouble();
      maxY = maxY.clamp(0, 100).toDouble();
    }

    return Column(
      children: [
        SizedBox(
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
                horizontalInterval: metric == VitalTrendMetric.heartRate
                    ? 20
                    : 2,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.black.withValues(alpha: 0.06),
                  strokeWidth: 1,
                ),
              ),

              borderData: FlBorderData(show: false),

              rangeAnnotations: hasNormalRange
                  ? RangeAnnotations(
                      horizontalRangeAnnotations: [
                        HorizontalRangeAnnotation(
                          y1: normalMin,
                          y2: normalMax,
                          color: const Color(
                            0xFF55B982,
                          ).withValues(alpha: 0.10),
                        ),
                      ],
                    )
                  : const RangeAnnotations(),

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
                getTouchedSpotIndicator: (barData, spotIndexes) {
                  return spotIndexes.map((spotIndex) {
                    final spot = barData.spots[spotIndex];
                    final point = trend.points.firstWhere(
                      (candidate) => _xFor(candidate.recordedAt) == spot.x,
                    );
                    final color = _severityColor(point.severity, lineColor);

                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: color.withValues(alpha: 0.45),
                        strokeWidth: 1,
                      ),
                      FlDotData(
                        getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                          radius: 6,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                    );
                  }).toList();
                },
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final point = segments[spot.barIndex][spot.spotIndex];

                      return LineTooltipItem(
                        'Average: ${_formatValue(point.value)} ${trend.unit}\n'
                        'Low: ${_formatValue(point.minimum)}  '
                        'High: ${_formatValue(point.maximum)}\n'
                        'Readings: ${point.readingCount}\n'
                        'Highest severity: ${_severityLabel(point.severity)}\n'
                        '${_tooltipPeriod(point.recordedAt)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          height: 1.35,
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
                          (point) =>
                              FlSpot(_xFor(point.recordedAt), point.value),
                        )
                        .toList(),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, _) {
                        final point = segment.firstWhere(
                          (candidate) => _xFor(candidate.recordedAt) == spot.x,
                        );
                        return point.severity != VitalTrendSeverity.info ||
                            segment.length == 1;
                      },
                      getDotPainter: (spot, percent, barData, index) {
                        final point = segment[index];
                        final color = _severityColor(point.severity, lineColor);
                        final radius = switch (point.severity) {
                          VitalTrendSeverity.warning => 4.0,
                          VitalTrendSeverity.critical => 4.5,
                          VitalTrendSeverity.info ||
                          VitalTrendSeverity.unknown => 3.0,
                        };

                        return FlDotCirclePainter(
                          radius: radius,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
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
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            if (hasNormalRange)
              _TrendLegendItem(
                color: const Color(0xFF55B982),
                label:
                    'Normal range (${_formatValue(normalMin)}–'
                    '${_formatValue(normalMax)} ${trend.unit})',
                isRange: true,
              ),
            _TrendLegendItem(color: lineColor, label: 'Normal'),
            const _TrendLegendItem(color: Color(0xFFFFB900), label: 'Warning'),
            const _TrendLegendItem(color: Color(0xFFFF6467), label: 'Critical'),
          ],
        ),
      ],
    );
  }

  Color _severityColor(VitalTrendSeverity severity, Color normalColor) {
    return switch (severity) {
      VitalTrendSeverity.warning => const Color(0xFFFFB900),
      VitalTrendSeverity.critical => const Color(0xFFFF6467),
      VitalTrendSeverity.info || VitalTrendSeverity.unknown => normalColor,
    };
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

  String _formatValue(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  String _severityLabel(VitalTrendSeverity severity) {
    return switch (severity) {
      VitalTrendSeverity.info => 'Normal',
      VitalTrendSeverity.warning => 'Warning',
      VitalTrendSeverity.critical => 'Critical',
      VitalTrendSeverity.unknown => 'Unknown',
    };
  }

  String _tooltipPeriod(DateTime value) {
    final local = value.toLocal();

    if (trend.resolution == '1h') {
      final end = local.add(const Duration(hours: 1));
      return '${local.month}/${local.day}/${local.year} • '
          '${_clockTime(local)}–${_clockTime(end)}';
    }

    return '${local.month}/${local.day}/${local.year}';
  }

  String _clockTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final period = value.hour >= 12 ? 'PM' : 'AM';

    return '$hour:${value.minute.toString().padLeft(2, '0')} $period';
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

class _TrendLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isRange;

  const _TrendLegendItem({
    required this.color,
    required this.label,
    this.isRange = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isRange ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isRange ? 0.18 : 1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF6B6385)),
        ),
      ],
    );
  }
}
