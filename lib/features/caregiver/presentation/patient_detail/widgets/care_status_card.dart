import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/alera_typography.dart';
import '../../../../../design_system/widgets/alera_card.dart';
import '../../../../../design_system/widgets/alera_pill.dart';
import '../../../../../design_system/widgets/alera_svg_icon.dart';
import '../../../domain/models/care_recipient.dart';
import '../../../domain/models/health_snapshot.dart';

/// The one answer to "is the patient OK right now?": status, one-line
/// summary, and small chips for last check-in, active alerts and today's
/// reminders. Care risk only appears once an assessment exists.
class PatientCareStatusCard extends StatelessWidget {
  final CareRecipient careRecipient;
  final int activeAlertCount;

  const PatientCareStatusCard({
    super.key,
    required this.careRecipient,
    this.activeAlertCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final CareStatus status = careRecipient.status;
    final HealthSnapshot snapshot = careRecipient.healthSnapshot;
    final String riskLabel = snapshot.careRiskLabel.trim();
    final bool riskAvailable =
        riskLabel.isNotEmpty && riskLabel.toLowerCase() != 'not assessed';
    final int reminders = careRecipient.reminderCount;

    return AleraCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AleraSvgIcon(
                assetPath: _statusIcon(status),
                width: 52,
                height: 52,
                semanticLabel: _statusTitle(status),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusTitle(status),
                      style: AleraTypography.sectionTitle.copyWith(
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusDescription(status),
                      style: AleraTypography.body.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AleraPill(
                variant: AleraPillVariant.label,
                leading: const Icon(
                  Icons.schedule,
                  size: 14,
                  color: AleraColors.textSecondary,
                ),
                label: snapshot.hasLastCheckIn
                    ? 'Checked in ${_time(snapshot.lastCheckIn)}'
                    : 'No check-in yet',
              ),
              AleraPill(
                variant: AleraPillVariant.label,
                leading: Icon(
                  Icons.notifications_active,
                  size: 14,
                  color: activeAlertCount > 0
                      ? AleraColors.critical
                      : AleraColors.textSecondary,
                ),
                label: activeAlertCount == 1
                    ? '1 active alert'
                    : '$activeAlertCount active alerts',
              ),
              AleraPill(
                variant: AleraPillVariant.label,
                leading: const Icon(
                  Icons.alarm,
                  size: 14,
                  color: AleraColors.textSecondary,
                ),
                label: reminders == 1
                    ? '1 reminder today'
                    : '$reminders reminders today',
              ),
              if (riskAvailable)
                AleraPill(
                  variant: AleraPillVariant.label,
                  leading: const Icon(
                    Icons.health_and_safety,
                    size: 14,
                    color: AleraColors.textSecondary,
                  ),
                  label: 'Care risk: $riskLabel (${snapshot.careRiskScore})',
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _time(DateTime value) {
    final int hour = value.hour == 0
        ? 12
        : value.hour > 12
        ? value.hour - 12
        : value.hour;
    return '$hour:${value.minute.toString().padLeft(2, '0')} '
        '${value.hour >= 12 ? 'PM' : 'AM'}';
  }
}

String _statusTitle(CareStatus status) => switch (status) {
  CareStatus.stable => 'Stable',
  CareStatus.warning => 'Warning',
  CareStatus.critical => 'Critical',
  CareStatus.needsAttention => 'Needs Attention',
  CareStatus.noData => 'No Data',
  CareStatus.unknown => 'Unknown',
};

String _statusDescription(CareStatus status) => switch (status) {
  CareStatus.stable => 'Everything looks steady right now.',
  CareStatus.warning => 'One or more readings need a closer look.',
  CareStatus.critical => 'Immediate attention may be needed.',
  CareStatus.needsAttention => 'Something may need follow-up.',
  CareStatus.noData => 'No recent readings are available yet.',
  CareStatus.unknown => 'We’re checking the latest health information.',
};

String _statusIcon(CareStatus status) => switch (status) {
  CareStatus.stable => 'alera-figma-assets/assets/icons/status/stable.svg',
  CareStatus.warning || CareStatus.needsAttention =>
    'alera-figma-assets/assets/icons/status/warning.svg',
  CareStatus.critical => 'alera-figma-assets/assets/icons/status/critical.svg',
  CareStatus.noData ||
  CareStatus.unknown => 'alera-figma-assets/assets/icons/status/info.svg',
};
