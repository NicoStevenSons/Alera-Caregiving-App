import 'package:flutter/material.dart';

import '../../../../../design_system/alera_typography.dart';
import '../../../../../design_system/widgets/alera_section_card.dart';
import '../../../../../design_system/widgets/alera_svg_icon.dart';
import '../../../domain/models/health_snapshot.dart';

class HomeTodayOverviewCard extends StatelessWidget {
  final HealthSnapshot snapshot;

  const HomeTodayOverviewCard({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return AleraSectionCard(
      title: "Today's overview",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OverviewRow(
            assetPath: 'alera-figma-assets/assets/icons/mini_status/activity.svg',
            title: snapshot.steps == null
                ? 'No step data available today'
                : '${snapshot.steps} steps recorded today',
            detail: snapshot.stepsUpdatedAt == null
                ? null
                : 'As of ${_time(snapshot.stepsUpdatedAt!)}',
          ),
          const SizedBox(height: 12),
          _OverviewRow(
            assetPath: 'alera-figma-assets/assets/icons/mini_status/sleep.svg',
            title: snapshot.sleepDuration == Duration.zero ||
                    snapshot.sleepDate == null
                ? 'No completed sleep session recorded'
                : 'Last recorded sleep: ${_duration(snapshot.sleepDuration)}',
            detail: snapshot.sleepDuration == Duration.zero ||
                    snapshot.sleepDate == null
                ? null
                : 'Recorded ${_date(snapshot.sleepDate!)}',
          ),
        ],
      ),
    );
  }

  String _duration(Duration value) =>
      '${value.inHours}h ${value.inMinutes.remainder(60)}m';

  String _time(DateTime value) {
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _date(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }
}

class _OverviewRow extends StatelessWidget {
  final String assetPath;
  final String title;
  final String? detail;

  const _OverviewRow({
    required this.assetPath,
    required this.title,
    required this.detail,
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
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AleraTypography.label),
              if (detail != null) ...[
                const SizedBox(height: 2),
                Text(detail!, style: AleraTypography.micro),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
