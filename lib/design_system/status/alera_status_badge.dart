import 'package:flutter/material.dart';

import 'alera_status_descriptor.dart';
import 'alera_status_icon.dart';
import 'alera_status_tone.dart';

/// Compact, icon-only circular status indicator.
///
/// The foundational primitive for [AleraBadgedAvatar] (Patch 3), which overlays
/// this in the bottom-right corner of a patient photo in multi-patient feeds.
/// Also usable standalone wherever a dense, glyph-only status mark is wanted.
///
/// Because this widget carries no visible label, [AleraStatusDescriptor.label]
/// (or [labelOverride]) is still required and used as the accessible name —
/// the glyph alone is not enough for a screen reader.
///
/// The background is the tone's saturated `foreground` colour, not its soft
/// `fill` — a badge this small, sitting on a photo of any brightness, needs
/// full-strength colour and a white glyph to stay legible, unlike
/// [AleraStatusChip]'s larger, softer pill.
class AleraStatusBadge extends StatelessWidget {
  final AleraStatusDescriptor descriptor;

  /// Overrides the accessible label without changing tone or glyph.
  final String? labelOverride;

  /// Outer diameter of the badge, including the ring.
  final double diameter;

  /// Glyph colour drawn on the solid tone background. Defaults to white,
  /// which is legible against every tone's `foreground` colour in both
  /// themes.
  final Color glyphColor;

  /// Ring colour, drawn as a solid border outside the tone fill so the badge
  /// doesn't bleed into whatever photo or surface it sits on. Defaults to the
  /// ambient surface colour, which is correct when the badge sits directly on
  /// a card; callers overlaying a differently-coloured card should pass their
  /// own.
  final Color? ringColor;

  /// Ring thickness. 1.5–2px per the agreed spec; defaults to 2.
  final double ringWidth;

  const AleraStatusBadge({
    super.key,
    required this.descriptor,
    this.labelOverride,
    this.diameter = 20,
    this.glyphColor = Colors.white,
    this.ringColor,
    this.ringWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    final AleraStatusPalette palette = descriptor.paletteOf(context);
    final Color resolvedRingColor =
        ringColor ?? Theme.of(context).colorScheme.surface;
    final String semanticLabel =
        descriptor.semanticLabel ?? labelOverride ?? descriptor.label;

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.foreground,
          border: Border.all(color: resolvedRingColor, width: ringWidth),
        ),
        alignment: Alignment.center,
        child: AleraStatusIcon(
          glyph: descriptor.glyph,
          size: diameter * 0.6,
          color: glyphColor,
        ),
      ),
    );
  }
}
