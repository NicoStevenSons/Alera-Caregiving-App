import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/alera_typography.dart';
import '../../../../../design_system/widgets/alera_card.dart';
import '../../../../../design_system/widgets/alera_svg_icon.dart';
import '../../../domain/models/care_recipient.dart';

class HomeHealthSummary extends StatelessWidget {
  final CareRecipient careRecipient;
  final ValueChanged<String> onMetricTap;

  const HomeHealthSummary({
    super.key,
    required this.careRecipient,
    required this.onMetricTap,
  });

  @override
  Widget build(BuildContext context) {
    final snapshot = careRecipient.healthSnapshot;
    return AleraCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AleraSvgIcon(
                assetPath: careRecipient.status == CareStatus.stable
                    ? 'alera-figma-assets/assets/icons/status/stable.svg'
                    : 'alera-figma-assets/assets/icons/status/warning.svg',
                width: 20,
                height: 20,
                semanticLabel: 'Current health status',
              ),
              const SizedBox(width: 6),
              Text(
                _statusTitle(careRecipient.status),
                style: AleraTypography.sectionTitle.copyWith(fontSize: 17),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _statusDescription(careRecipient.status),
            style: AleraTypography.body.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  assetPath:
                      'alera-figma-assets/assets/icons/vitals/heart_rate.svg',
                  label: snapshot.heartRateBpm == null
                      ? 'No data'
                      : '${snapshot.heartRateBpm} ${snapshot.heartRateUnit ?? 'bpm'}',
                  timestamp: _timestamp(snapshot.heartRateRecordedAt),
                  color: const Color(0xFFFF7192),
                  onTap: () => onMetricTap('Heart Rate'),
                ),
              ),
              Expanded(
                child: _Metric(
                  assetPath: 'alera-figma-assets/assets/icons/vitals/spo2.svg',
                  label: snapshot.spo2Percent == null
                      ? 'No data'
                      : '${snapshot.spo2Percent!.toStringAsFixed(0)}${snapshot.spo2Unit ?? '%'}',
                  timestamp: _timestamp(snapshot.spo2RecordedAt),
                  color: const Color(0xFF9378F1),
                  onTap: () => onMetricTap('SpO2'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  assetPath:
                      'alera-figma-assets/assets/icons/vitals/stress.svg',
                  label: careRecipient.backendBacked
                      ? 'Stress — mock-only'
                      : snapshot.stressLabel,
                  color: const Color(0xFFFF875F),
                  onTap: () => onMetricTap('Stress'),
                ),
              ),
              Expanded(
                child: _Metric(
                  assetPath:
                      'alera-figma-assets/assets/icons/vitals/activity.svg',
                  label: careRecipient.backendBacked
                      ? 'Activity — mock-only'
                      : snapshot.steps == null
                      ? 'No activity'
                      : 'Active',
                  color: const Color(0xFF73C838),
                  onTap: () => onMetricTap('Activity'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timestamp(DateTime? value) =>
      value == null ? 'Unavailable' : _time(value.toLocal());

  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  String _statusDescription(CareStatus status) => switch (status) {
    CareStatus.stable => 'Everything looks steady right now.',
    CareStatus.warning => 'One or more readings need a closer look.',
    CareStatus.critical => 'Immediate attention may be needed.',
    CareStatus.needsAttention => 'Something may need follow-up.',
    CareStatus.noData => 'No recent readings are available yet.',
    CareStatus.unknown => 'We’re checking the latest health information.',
  };

  String _statusTitle(CareStatus status) => switch (status) {
    CareStatus.stable => 'Stable',
    CareStatus.warning => 'Warning',
    CareStatus.critical => 'Critical',
    CareStatus.needsAttention => 'Needs Attention',
    CareStatus.noData => 'No Data',
    CareStatus.unknown => 'Unknown',
  };
}

class _Metric extends StatelessWidget {
  final String assetPath;
  final String label;
  final String? timestamp;
  final Color color;
  final VoidCallback onTap;

  const _Metric({
    required this.assetPath,
    required this.label,
    this.timestamp,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                AleraSvgIcon(
                  assetPath: assetPath,
                  width: 20,
                  height: 20,
                  semanticLabel: label,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: timestamp == null
                      ? Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timestamp!,
                              style: const TextStyle(
                                color: AleraColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
