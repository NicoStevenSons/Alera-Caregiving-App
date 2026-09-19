import 'package:flutter/material.dart';

import '../../../features/caregiver/data/api/dto/vital_trend_dto.dart'
    show VitalTrendSeverity;
import '../alera_status_chip.dart';
import '../alera_status_descriptor.dart';
import '../alera_status_glyph.dart';
import '../alera_status_labels.dart';
import '../alera_status_tone.dart';

/// Which side of the normal range a vital reading fell on.
///
/// [VitalTrendSeverity] (the real backend model) only carries magnitude of
/// concern — `info` / `warning` / `critical` — not direction. There is no
/// existing enum for "above range" vs "below range" anywhere in the codebase;
/// this one exists solely so this adapter can pick a correct arrow rather than
/// guessing. A call site that has the actual reading and the patient's normal
/// range (`PatientDto.normalHrMin`/`normalHrMax`,
/// `usualSpo2Min`/`usualSpo2Max`) should compare them and pass the result
/// here. Passing null renders a direction-neutral label and icon — correct
/// for `info`/`unknown` severity, a fallback (not a claim of accuracy) for
/// `warning`/`critical`.
enum VitalTrendDirection { aboveRange, belowRange }

/// Maps a [VitalTrendSeverity] and, when known, a [VitalTrendDirection] to an
/// [AleraStatusChip].
///
/// Kept off `AleraStatusDot` deliberately: a dot carries no glyph, so an
/// elevated dot and a low dot (or a merely-elevated dot and a dangerously-high
/// one) would be visually identical amber or red circles. This chip's arrow
/// and its label are what actually distinguish them.
class VitalTrendChip extends StatelessWidget {
  final VitalTrendSeverity severity;
  final VitalTrendDirection? direction;
  final String? labelOverride;
  final AleraStatusChipSize size;

  const VitalTrendChip(
    this.severity, {
    super.key,
    this.direction,
    this.labelOverride,
    this.size = AleraStatusChipSize.medium,
  });

  static AleraStatusDescriptor describe(
    VitalTrendSeverity severity,
    BuildContext context, {
    VitalTrendDirection? direction,
  }) {
    final AleraStatusLabels labels = AleraStatusLabels.of(context);

    return switch (severity) {
      VitalTrendSeverity.info => AleraStatusDescriptor(
        tone: AleraStatusTone.success,
        glyph: const AleraStatusGlyph.material(Icons.remove),
        label: labels.vitalNormal,
      ),
      VitalTrendSeverity.warning => switch (direction) {
        VitalTrendDirection.aboveRange => AleraStatusDescriptor(
          tone: AleraStatusTone.warning,
          glyph: const AleraStatusGlyph.material(Icons.arrow_upward),
          label: labels.vitalElevated,
        ),
        VitalTrendDirection.belowRange => AleraStatusDescriptor(
          tone: AleraStatusTone.warning,
          glyph: const AleraStatusGlyph.material(Icons.arrow_downward),
          label: labels.vitalLow,
        ),
        null => AleraStatusDescriptor(
          tone: AleraStatusTone.warning,
          glyph: const AleraStatusGlyph.material(Icons.warning_amber),
          label: labels.vitalWarning,
        ),
      },
      VitalTrendSeverity.critical => switch (direction) {
        VitalTrendDirection.aboveRange => AleraStatusDescriptor(
          tone: AleraStatusTone.critical,
          glyph: const AleraStatusGlyph.material(Icons.arrow_upward),
          label: labels.vitalHigh,
        ),
        VitalTrendDirection.belowRange => AleraStatusDescriptor(
          tone: AleraStatusTone.critical,
          glyph: const AleraStatusGlyph.material(Icons.arrow_downward),
          label: labels.vitalCriticallyLow,
        ),
        null => AleraStatusDescriptor(
          tone: AleraStatusTone.critical,
          glyph: const AleraStatusGlyph.material(Icons.error),
          label: labels.vitalCritical,
        ),
      },
      VitalTrendSeverity.unknown => AleraStatusDescriptor(
        tone: AleraStatusTone.neutral,
        glyph: const AleraStatusGlyph.material(Icons.help_outline),
        label: labels.vitalUnknown,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AleraStatusChip(
      descriptor: describe(severity, context, direction: direction),
      labelOverride: labelOverride,
      size: size,
    );
  }
}
