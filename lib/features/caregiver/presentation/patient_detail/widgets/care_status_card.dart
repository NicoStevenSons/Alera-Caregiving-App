import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../domain/models/care_recipient.dart';
import 'patient_summary_card.dart';

/// Slim explanation banner under the header. Only shown when the patient is
/// not stable (Warning / Critical / Needs attention), so the page stays calm
/// when things are fine and gets louder only when something is wrong.
class PatientStatusBanner extends StatelessWidget {
  final CareStatus status;

  const PatientStatusBanner({super.key, required this.status});

  /// Whether this status warrants a banner at all.
  static bool shouldShow(CareStatus status) =>
      status == CareStatus.warning ||
      status == CareStatus.critical ||
      status == CareStatus.needsAttention;

  @override
  Widget build(BuildContext context) {
    final Color color = patientStatusColor(status);
    return Container(
      key: const Key('patient-status-banner'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            status == CareStatus.critical ? Icons.error : Icons.warning,
            size: 22,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _description(status),
              style: const TextStyle(
                color: AleraColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _description(CareStatus status) => switch (status) {
    CareStatus.warning => 'One or more readings need a closer look.',
    CareStatus.critical => 'Immediate attention may be needed.',
    CareStatus.needsAttention => 'Something may need follow-up.',
    _ => '',
  };
}
