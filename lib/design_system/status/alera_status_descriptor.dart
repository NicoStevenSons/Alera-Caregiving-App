import 'package:flutter/material.dart';

import 'alera_status_glyph.dart';
import 'alera_status_tone.dart';

/// Everything a status renderer needs, and nothing about where it came from.
///
/// Descriptors are produced by per-domain adapters at build time, after labels
/// have been resolved for the current locale. Renderers therefore stay pure and
/// golden-testable with no localisation harness, and `design_system` imports
/// nothing from `models/` or `features/`.
@immutable
class AleraStatusDescriptor {
  /// Urgency tone. Never the sole carrier of meaning.
  final AleraStatusTone tone;

  /// Glyph that distinguishes this state from others sharing its [tone].
  final AleraStatusGlyph glyph;

  /// Visible label, already localised.
  final String label;

  /// Screen reader label. Falls back to [label] when null.
  final String? semanticLabel;

  const AleraStatusDescriptor({
    required this.tone,
    required this.glyph,
    required this.label,
    this.semanticLabel,
  });

  /// Label announced by assistive technology.
  String get effectiveSemanticLabel => semanticLabel ?? label;

  /// Resolves this descriptor's colours against the ambient theme.
  AleraStatusPalette paletteOf(BuildContext context) =>
      AleraStatusColors.of(context).resolve(tone);

  AleraStatusDescriptor copyWith({
    AleraStatusTone? tone,
    AleraStatusGlyph? glyph,
    String? label,
    String? semanticLabel,
  }) {
    return AleraStatusDescriptor(
      tone: tone ?? this.tone,
      glyph: glyph ?? this.glyph,
      label: label ?? this.label,
      semanticLabel: semanticLabel ?? this.semanticLabel,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AleraStatusDescriptor &&
        other.tone == tone &&
        other.glyph == glyph &&
        other.label == label &&
        other.semanticLabel == semanticLabel;
  }

  @override
  int get hashCode => Object.hash(tone, glyph, label, semanticLabel);
}
