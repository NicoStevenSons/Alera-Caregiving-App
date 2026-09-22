import 'package:flutter/material.dart';

import '../../../features/caregiver/domain/models/caregiver_alert.dart';
import '../alera_status_chip.dart';
import '../alera_status_descriptor.dart';
import '../alera_status_glyph.dart';
import '../alera_status_labels.dart';
import '../alera_status_tone.dart';

/// Maps [CaregiverAlertSeverity] to an [AleraStatusChip].
///
/// [CaregiverAlertSeverity] currently has only `warning` and `critical` — there
/// is no `info` alert severity in the domain model. If one is added later,
/// this adapter's `switch` will fail to compile until a case is added for it,
/// which is the point: an unhandled severity should never silently render as
/// something else.
class AlertSeverityChip extends StatelessWidget {
  final CaregiverAlertSeverity severity;
  final String? labelOverride;
  final AleraStatusChipSize size;

  const AlertSeverityChip(
    this.severity, {
    super.key,
    this.labelOverride,
    this.size = AleraStatusChipSize.medium,
  });

  static AleraStatusDescriptor describe(
    CaregiverAlertSeverity severity,
    BuildContext context,
  ) {
    final AleraStatusLabels labels = AleraStatusLabels.of(context);

    return switch (severity) {
      CaregiverAlertSeverity.critical => AleraStatusDescriptor(
        tone: AleraStatusTone.critical,
        glyph: const AleraStatusGlyph.material(Icons.error),
        label: labels.alertCritical,
      ),
      CaregiverAlertSeverity.warning => AleraStatusDescriptor(
        tone: AleraStatusTone.warning,
        glyph: const AleraStatusGlyph.material(Icons.warning_amber),
        label: labels.alertWarning,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AleraStatusChip(
      descriptor: describe(severity, context),
      labelOverride: labelOverride,
      size: size,
    );
  }
}
