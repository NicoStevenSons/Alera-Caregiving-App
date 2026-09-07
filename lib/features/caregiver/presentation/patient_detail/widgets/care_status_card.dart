import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/alera_typography.dart';
import '../../../../../design_system/widgets/alera_card.dart';
import '../../../../../design_system/widgets/alera_svg_icon.dart';
import '../../../domain/models/care_recipient.dart';
import '../../../domain/models/health_snapshot.dart';

class PatientCareStatusCard extends StatelessWidget {
  final CareRecipient careRecipient;

  const PatientCareStatusCard({super.key, required this.careRecipient});

  @override
  Widget build(BuildContext context) {
    return AleraCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AleraCard(
            padding: const EdgeInsets.all(8),
            child: _StatusSection(careRecipient: careRecipient),
          ),
          const SizedBox(height: 12),
          AleraCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(child: _RiskDetails(careRecipient: careRecipient)),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Unavailable',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AleraColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  final CareRecipient careRecipient;

  const _StatusSection({required this.careRecipient});

  @override
  Widget build(BuildContext context) {
    final CareStatus status = careRecipient.status;
    final HealthSnapshot snapshot = careRecipient.healthSnapshot;
    return Row(
      children: [
        AleraSvgIcon(
          assetPath: _statusIcon(status),
          width: 48,
          height: 48,
          semanticLabel: _statusTitle(status),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_statusTitle(status), style: AleraTypography.sectionTitle),
              Text(
                _statusDescription(status),
                style: AleraTypography.body.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                snapshot.hasLastCheckIn
                    ? '◷ Last Check-in: ${_time(snapshot.lastCheckIn)}'
                    : '◷ Last Check-in: Unavailable',
                style: const TextStyle(color: Color(0xFFAA91DD), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
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

class _RiskDetails extends StatelessWidget {
  final CareRecipient careRecipient;

  const _RiskDetails({required this.careRecipient});

  @override
  Widget build(BuildContext context) {
    final HealthSnapshot snapshot = careRecipient.healthSnapshot;
    final String label = snapshot.careRiskLabel.trim();
    final bool available =
        label.isNotEmpty && label.toLowerCase() != 'not assessed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Care Risk', style: AleraTypography.sectionTitle),
        const SizedBox(height: 8),
        if (available) ...[
          Text(
            '${snapshot.careRiskScore}',
            style: const TextStyle(
              color: AleraColors.textPrimary,
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: AleraTypography.body.copyWith(fontSize: 13)),
          const SizedBox(height: 4),
          const Text(
            'Closer attention advised.',
            style: TextStyle(color: AleraColors.textSecondary, fontSize: 11),
          ),
        ] else ...[
          const Text(
            'Not assessed',
            style: TextStyle(
              color: AleraColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No risk assessment is available yet.',
            style: AleraTypography.body.copyWith(fontSize: 12),
          ),
        ],
      ],
    );
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
