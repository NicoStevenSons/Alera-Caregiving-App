import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/alera_typography.dart';
import '../../../../../design_system/widgets/alera_section_card.dart';
import '../../../../../design_system/widgets/alera_svg_icon.dart';
import '../../../domain/models/health_snapshot.dart';

class HomeInsightsCard extends StatelessWidget {
  final HealthSnapshot snapshot;
  final bool backendBacked;

  const HomeInsightsCard({
    super.key,
    required this.snapshot,
    this.backendBacked = false,
  });

  @override
  Widget build(BuildContext context) {
    final String sleep =
        '${snapshot.sleepDuration.inHours}h ${snapshot.sleepDuration.inMinutes.remainder(60)}m';
    return AleraSectionCard(
      title: "Today's Insights",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Insight(
            assetPath: 'alera-figma-assets/assets/icons/mini_status/spo2.svg',
            color: const Color(0xFF8A78F0),
            title: backendBacked
                ? 'Overnight SpO2 insight unavailable'
                : snapshot.spo2Percent == null
                ? 'No overnight SpO2 reading'
                : 'SpO2 stayed stable overnight',
            subtitle: backendBacked
                ? 'Overnight insight remains mock-only'
                : snapshot.spo2Percent == null
                ? 'No backend reading available'
                : '${(snapshot.spo2Percent! - 1).toStringAsFixed(0)} - ${snapshot.spo2Percent!.toStringAsFixed(0)}% while sleeping',
          ),
          const SizedBox(height: 10),
          _Insight(
            assetPath:
                'alera-figma-assets/assets/icons/mini_status/activity.svg',
            color: const Color(0xFF79CF2E),
            title: backendBacked
                ? 'Activity insight unavailable'
                : snapshot.steps == null
                ? 'No activity data today'
                : 'Low activity today',
            subtitle: backendBacked
                ? 'Activity remains mock-only'
                : snapshot.steps == null
                ? 'Activity remains mock-only'
                : '${snapshot.steps} steps recorded',
          ),
          const SizedBox(height: 10),
          _Insight(
            assetPath: 'alera-figma-assets/assets/icons/mini_status/sleep.svg',
            color: const Color(0xFF9A72F0),
            title: backendBacked
                ? 'Sleep insight unavailable'
                : snapshot.sleepDuration == Duration.zero
                ? 'Sleep data unavailable'
                : 'Slept $sleep',
            subtitle: 'Sleep remains mock-only',
          ),
        ],
      ),
    );
  }
}

class _Insight extends StatelessWidget {
  final String assetPath;
  final Color color;
  final String title;
  final String subtitle;

  const _Insight({
    required this.assetPath,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AleraSvgIcon(
          assetPath: assetPath,
          width: 20,
          height: 20,
          semanticLabel: title,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AleraTypography.label.copyWith(
                  color: AleraColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AleraTypography.body.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
