import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/widgets/alera_card.dart';
import '../../../domain/models/care_recipient.dart';
import 'patient_summary_card.dart';

/// Compact one-line status summary: a coloured dot, the status, and a short
/// plain-language reason with the active alert count.
class PatientStatusSummaryCard extends StatelessWidget {
  final CareStatus status;
  final int activeAlertCount;

  const PatientStatusSummaryCard({
    super.key,
    required this.status,
    required this.activeAlertCount,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = patientStatusColor(status);
    return AleraCard(
      key: const Key('patient-status-summary'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon(status), size: 20, color: color),
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
            activeAlertCount == 1 ? '1 active alert' : '$activeAlertCount active alerts',
            style: const TextStyle(
              color: AleraColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon(CareStatus status) => switch (status) {
    CareStatus.stable => Icons.check_circle,
    CareStatus.critical => Icons.error,
    CareStatus.warning || CareStatus.needsAttention => Icons.warning,
    CareStatus.noData || CareStatus.unknown => Icons.help,
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
