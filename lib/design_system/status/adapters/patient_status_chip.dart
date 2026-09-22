import 'package:flutter/material.dart';

import '../../../features/caregiver/domain/models/care_recipient.dart';
import '../alera_status_chip.dart';
import '../alera_status_descriptor.dart';
import '../alera_status_glyph.dart';
import '../alera_status_labels.dart';
import '../alera_status_tone.dart';

/// Maps [CareStatus] — a patient's health/monitoring status — to an
/// [AleraStatusChip].
///
/// This is a different domain from patient *access* state (whether the
/// patient's account is connected — `PatientAccessState` in the API layer):
/// the original five-domain plan's "Patient State" referred to access state
/// (Active / Pending Access / Inactive) and remains unbuilt. This adapter
/// covers what the Patch 4 directive actually asked for under the same name —
/// Stable / Attention needed / Critical — which is [CareStatus].
///
/// `warning` and `needsAttention` share an amber tone; they're told apart by
/// icon and label since telling them apart by a colour split would have been
/// a guess about intended UX. Drop whichever of the two you don't need.
class PatientStatusChip extends StatelessWidget {
  final CareStatus status;
  final String? labelOverride;
  final AleraStatusChipSize size;

  const PatientStatusChip(
    this.status, {
    super.key,
    this.labelOverride,
    this.size = AleraStatusChipSize.medium,
  });

  static AleraStatusDescriptor describe(
    CareStatus status,
    BuildContext context,
  ) {
    final AleraStatusLabels labels = AleraStatusLabels.of(context);

    return switch (status) {
      CareStatus.critical => AleraStatusDescriptor(
        tone: AleraStatusTone.critical,
        glyph: const AleraStatusGlyph.material(Icons.error),
        label: labels.patientStatusCritical,
      ),
      CareStatus.warning => AleraStatusDescriptor(
        tone: AleraStatusTone.warning,
        glyph: const AleraStatusGlyph.material(Icons.warning_amber),
        label: labels.patientStatusWarning,
      ),
      CareStatus.needsAttention => AleraStatusDescriptor(
        tone: AleraStatusTone.warning,
        glyph: const AleraStatusGlyph.material(Icons.flag),
        label: labels.patientStatusNeedsAttention,
      ),
      CareStatus.stable => AleraStatusDescriptor(
        tone: AleraStatusTone.success,
        glyph: const AleraStatusGlyph.material(Icons.check_circle_outline),
        label: labels.patientStatusStable,
      ),
      CareStatus.noData => AleraStatusDescriptor(
        tone: AleraStatusTone.neutral,
        glyph: const AleraStatusGlyph.material(Icons.remove_circle_outline),
        label: labels.patientStatusNoData,
      ),
      CareStatus.unknown => AleraStatusDescriptor(
        tone: AleraStatusTone.neutral,
        glyph: const AleraStatusGlyph.material(Icons.help_outline),
        label: labels.patientStatusUnknown,
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
