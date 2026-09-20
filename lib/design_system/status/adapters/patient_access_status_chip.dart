import 'package:flutter/material.dart';

import '../../../features/caregiver/data/api/dto/patient_dto.dart'
    show PatientAccessState;
import '../alera_status_chip.dart';
import '../alera_status_descriptor.dart';
import '../alera_status_glyph.dart';
import '../alera_status_labels.dart';
import '../alera_status_tone.dart';

/// Maps [PatientAccessState] — whether the patient's own account is
/// connected to Alera — to an [AleraStatusChip].
///
/// This is the "Patient State" domain the original five-domain plan named
/// (Active / Pending access / Inactive) and that [AleraStatusLabels] already
/// carries labels for (`patientActive`, `patientPendingAccess`,
/// `patientInactive`); [PatientStatusChip] covers a different domain (the
/// patient's health/monitoring status, `CareStatus`), not this one. This
/// adapter is the first consumer of those three getters.
class PatientAccessStatusChip extends StatelessWidget {
  final PatientAccessState status;
  final String? labelOverride;
  final AleraStatusChipSize size;

  const PatientAccessStatusChip(
    this.status, {
    super.key,
    this.labelOverride,
    this.size = AleraStatusChipSize.medium,
  });

  static AleraStatusDescriptor describe(
    PatientAccessState status,
    BuildContext context,
  ) {
    final AleraStatusLabels labels = AleraStatusLabels.of(context);

    return switch (status) {
      PatientAccessState.connected => AleraStatusDescriptor(
        tone: AleraStatusTone.success,
        glyph: const AleraStatusGlyph.material(Icons.check_circle_outline),
        label: labels.patientActive,
      ),
      PatientAccessState.invitePending => AleraStatusDescriptor(
        tone: AleraStatusTone.info,
        glyph: const AleraStatusGlyph.material(Icons.hourglass_top),
        label: labels.patientPendingAccess,
      ),
      PatientAccessState.notConnected => AleraStatusDescriptor(
        tone: AleraStatusTone.neutral,
        glyph: const AleraStatusGlyph.material(Icons.link_off),
        label: labels.patientInactive,
      ),
      PatientAccessState.unknown => AleraStatusDescriptor(
        tone: AleraStatusTone.neutral,
        glyph: const AleraStatusGlyph.material(Icons.help_outline),
        label: labels.patientInactive,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AleraStatusChip(
      descriptor: describe(status, context),
      labelOverride: labelOverride,
      size: size,
    );
  }
}
