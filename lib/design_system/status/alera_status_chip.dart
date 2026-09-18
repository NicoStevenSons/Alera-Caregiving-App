import 'package:flutter/material.dart';

import 'alera_status_descriptor.dart';
import 'alera_status_icon.dart';
import 'alera_status_tone.dart';

/// Size variant for [AleraStatusChip].
enum AleraStatusChipSize { small, medium }

@immutable
class _ChipMetrics {
  final EdgeInsets padding;
  final double iconSize;
  final double gap;
  final double fontSize;

  const _ChipMetrics({
    required this.padding,
    required this.iconSize,
    required this.gap,
    required this.fontSize,
  });
}

const Map<AleraStatusChipSize, _ChipMetrics> _metrics =
    <AleraStatusChipSize, _ChipMetrics>{
      AleraStatusChipSize.small: _ChipMetrics(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        iconSize: 12,
        gap: 4,
        fontSize: 11,
      ),
      AleraStatusChipSize.medium: _ChipMetrics(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        iconSize: 14,
        gap: 6,
        fontSize: 12,
      ),
    };

/// Read-only pill-shaped status indicator: glyph plus label.
///
/// For single-patient views and dashboards where the patient's identity is
/// already established by context, so the status itself is the thing worth
/// showing. In a multi-patient feed, use [AleraStatusBadge] overlaid on the
/// patient's avatar instead — this widget does not identify who the status
/// belongs to.
///
/// Colours come strictly from [AleraStatusColors.of], resolved by the
/// descriptor's [AleraStatusTone]. No colour is ever hardcoded here, so light
/// and dark mode are handled entirely by the registered theme extension.
class AleraStatusChip extends StatelessWidget {
  final AleraStatusDescriptor descriptor;

  /// Overrides the visible label without changing the descriptor's tone or
  /// glyph. Falls back to [AleraStatusDescriptor.label].
  final String? labelOverride;

  final AleraStatusChipSize size;

  const AleraStatusChip({
    super.key,
    required this.descriptor,
    this.labelOverride,
    this.size = AleraStatusChipSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final AleraStatusPalette palette = descriptor.paletteOf(context);
    final _ChipMetrics metrics = _metrics[size]!;
    final String label = labelOverride ?? descriptor.label;
    final String semanticLabel = descriptor.semanticLabel ?? label;

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.fill,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: palette.border, width: 1),
        ),
        child: Padding(
          padding: metrics.padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AleraStatusIcon(
                glyph: descriptor.glyph,
                size: metrics.iconSize,
                color: palette.foreground,
              ),
              SizedBox(width: metrics.gap),
              Text(
                label,
                style: TextStyle(
                  color: palette.foreground,
                  fontSize: metrics.fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
