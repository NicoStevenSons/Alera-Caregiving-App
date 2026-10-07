import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/widgets/alera_card.dart';
import '../../../../../design_system/widgets/alera_svg_icon.dart';
import '../../../domain/models/care_recipient.dart';
import 'patient_summary_card.dart';

/// Compact one-line status summary: a coloured dot, the status, and a short
/// plain-language reason with the active alert count.
class PatientStatusSummaryCard extends StatelessWidget {
  final CareStatus status;
  final int activeAlertCount;
  final int careRiskScore;
  final String careRiskLabel;

  const PatientStatusSummaryCard({
    super.key,
    required this.status,
    required this.activeAlertCount,
    required this.careRiskScore,
    required this.careRiskLabel,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = patientStatusColor(status);
    return AleraCard(
      key: const Key('patient-status-summary'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          _statusRow(color),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AleraColors.divider),
          ),
          _careRisk(),
        ],
      ),
    );
  }

  Widget _careRisk() {
    final bool assessed = careRiskScore > 0;
    final double fraction = (careRiskScore.clamp(0, 100)) / 100;
    return Row(
      key: const Key('patient-care-risk'),
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Care Risk',
                style: TextStyle(
                  color: AleraColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                assessed ? '$careRiskScore' : '--',
                style: const TextStyle(
                  color: AleraColors.textPrimary,
                  fontSize: 34,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                assessed ? careRiskLabel : 'Not assessed yet',
                style: const TextStyle(
                  color: AleraColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _RiskGauge(fraction: assessed ? fraction : 0),
      ],
    );
  }

  Widget _statusRow(Color color) {
    return Row(
      children: [
        AleraSvgIcon(
          assetPath: _statusAsset(status),
          width: 44,
          height: 44,
          semanticLabel: patientStatusTitle(status),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patientStatusTitle(status),
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _description(status),
                style: const TextStyle(
                  color: AleraColors.textSecondary,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          activeAlertCount == 1
              ? '1 active alert'
              : '$activeAlertCount active alerts',
          style: const TextStyle(
            color: AleraColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Figma status icons. No data / Unknown use the `error.svg` placeholder
  /// (listed in PLACEHOLDER_ICONS.md) until dedicated artwork exists.
  String _statusAsset(CareStatus status) => switch (status) {
    CareStatus.stable => 'alera-figma-assets/assets/icons/status/stable.svg',
    CareStatus.warning || CareStatus.needsAttention =>
      'alera-figma-assets/assets/icons/status/warning.svg',
    CareStatus.critical =>
      'alera-figma-assets/assets/icons/status/critical.svg',
    CareStatus.noData ||
    CareStatus.unknown => 'alera-figma-assets/assets/icons/status/error.svg',
  };

  String _description(CareStatus status) => switch (status) {
    CareStatus.stable => 'Readings look steady.',
    CareStatus.warning => 'A reading needs a closer look.',
    CareStatus.critical => 'Immediate attention may be needed.',
    CareStatus.needsAttention => 'Something may need follow-up.',
    CareStatus.noData => 'No recent readings.',
    CareStatus.unknown => 'Status not available yet.',
  };
}

/// Round fill-up gauge with a heart-shield in the middle.
class _RiskGauge extends StatelessWidget {
  final double fraction;

  const _RiskGauge({required this.fraction});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(92),
            painter: _GaugePainter(fraction),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: const [
                Icon(Icons.shield, size: 28, color: AleraColors.selected),
                Padding(
                  padding: EdgeInsets.only(bottom: 1),
                  child: Icon(Icons.favorite, size: 12, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double fraction;

  _GaugePainter(this.fraction);

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 11;
    final Rect rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    // 270 degree dial opening at the bottom, starting bottom-left.
    const double start = math.pi * 0.75;
    const double sweep = math.pi * 1.5;

    canvas.drawCircle(
      size.center(Offset.zero),
      size.width / 2,
      Paint()..color = AleraColors.primarySoft.withValues(alpha: 0.5),
    );

    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AleraColors.primarySoft;
    canvas.drawArc(rect.deflate(6), start, sweep, false, track);

    if (fraction <= 0) return;
    final Paint fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: 0,
        endAngle: sweep,
        colors: [Color(0xFFC9B2F5), AleraColors.selected],
        transform: GradientRotation(start),
      ).createShader(rect);
    canvas.drawArc(rect.deflate(6), start, sweep * fraction, false, fill);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.fraction != fraction;
}
