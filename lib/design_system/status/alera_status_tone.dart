import 'package:flutter/material.dart';

import '../alera_colors.dart';

/// Semantic severity tone shared by every Alera status domain.
///
/// Tone carries urgency only. It never carries meaning on its own: two domains
/// may legitimately share a tone (Reminder "Overdue" and Alert "Critical" are
/// both [critical]). Disambiguation is the job of the glyph and the label, so
/// colour is never the sole carrier of information (WCAG 1.4.1).
enum AleraStatusTone { critical, warning, success, info, neutral }

/// Resolved colours for a single tone.
@immutable
class AleraStatusPalette {
  /// Container fill behind the badge or chip.
  final Color fill;

  /// Icon and label colour drawn on top of [fill].
  final Color foreground;

  /// Hairline border. Used by outlined variants and by the ring around an
  /// overlay badge when it sits on a photo.
  final Color border;

  const AleraStatusPalette({
    required this.fill,
    required this.foreground,
    required this.border,
  });

  static AleraStatusPalette lerp(
    AleraStatusPalette a,
    AleraStatusPalette b,
    double t,
  ) {
    return AleraStatusPalette(
      fill: Color.lerp(a.fill, b.fill, t)!,
      foreground: Color.lerp(a.foreground, b.foreground, t)!,
      border: Color.lerp(a.border, b.border, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AleraStatusPalette &&
        other.fill == fill &&
        other.foreground == foreground &&
        other.border == border;
  }

  @override
  int get hashCode => Object.hash(fill, foreground, border);
}

/// Theme-scoped colour tokens for status badges, chips and dots.
///
/// Registered on [ThemeData.extensions] so status colours survive theme
/// switching without any widget reaching for a hardcoded [Color].
@immutable
class AleraStatusColors extends ThemeExtension<AleraStatusColors> {
  final AleraStatusPalette critical;
  final AleraStatusPalette warning;
  final AleraStatusPalette success;
  final AleraStatusPalette info;
  final AleraStatusPalette neutral;

  const AleraStatusColors({
    required this.critical,
    required this.warning,
    required this.success,
    required this.info,
    required this.neutral,
  });

  /// Light theme: fixed container tokens, hand-authored per tone.
  factory AleraStatusColors.light() {
    return const AleraStatusColors(
      critical: AleraStatusPalette(
        fill: Color(0xFFFFE8EB),
        foreground: Color(0xFFC62033),
        border: Color(0xFFFFC7CE),
      ),
      warning: AleraStatusPalette(
        fill: Color(0xFFFFF4D6),
        foreground: Color(0xFF8A5A00),
        border: Color(0xFFFFE3A3),
      ),
      success: AleraStatusPalette(
        fill: Color(0xFFDFFCF0),
        foreground: Color(0xFF00794C),
        border: Color(0xFFB4F2DA),
      ),
      info: AleraStatusPalette(
        fill: Color(0xFFE4F0FF),
        foreground: Color(0xFF1D5FB0),
        border: Color(0xFFC2DCFF),
      ),
      neutral: AleraStatusPalette(
        fill: Color(0xFFEFECF7),
        foreground: AleraColors.textSecondary,
        border: AleraColors.divider,
      ),
    );
  }

  /// Dark theme: low-opacity fills over the dark surface paired with
  /// hand-picked high-luminance foregrounds.
  ///
  /// Foregrounds are authored, not derived from the fill. Deriving them is what
  /// turns amber muddy on dark backgrounds.
  factory AleraStatusColors.dark() {
    return AleraStatusColors(
      critical: AleraStatusPalette(
        fill: const Color(0xFFFF6474).withValues(alpha: 0.15),
        foreground: const Color(0xFFFF9BA6),
        border: const Color(0xFFFF6474).withValues(alpha: 0.38),
      ),
      warning: AleraStatusPalette(
        fill: const Color(0xFFFFBE18).withValues(alpha: 0.15),
        foreground: const Color(0xFFFFD873),
        border: const Color(0xFFFFBE18).withValues(alpha: 0.38),
      ),
      success: AleraStatusPalette(
        fill: const Color(0xFF08D887).withValues(alpha: 0.15),
        foreground: const Color(0xFF5BE9B4),
        border: const Color(0xFF08D887).withValues(alpha: 0.38),
      ),
      info: AleraStatusPalette(
        fill: const Color(0xFF55A5FF).withValues(alpha: 0.15),
        foreground: const Color(0xFF93C6FF),
        border: const Color(0xFF55A5FF).withValues(alpha: 0.38),
      ),
      neutral: AleraStatusPalette(
        fill: const Color(0xFFB9B2CE).withValues(alpha: 0.15),
        foreground: const Color(0xFFC9C3DA),
        border: const Color(0xFFB9B2CE).withValues(alpha: 0.32),
      ),
    );
  }

  AleraStatusPalette resolve(AleraStatusTone tone) {
    return switch (tone) {
      AleraStatusTone.critical => critical,
      AleraStatusTone.warning => warning,
      AleraStatusTone.success => success,
      AleraStatusTone.info => info,
      AleraStatusTone.neutral => neutral,
    };
  }

  /// Reads the tokens from [context], falling back to the light set when no
  /// extension is registered. The fallback keeps widget tests that build a bare
  /// [MaterialApp] working without theme wiring.
  static AleraStatusColors of(BuildContext context) {
    return Theme.of(context).extension<AleraStatusColors>() ??
        AleraStatusColors.light();
  }

  @override
  AleraStatusColors copyWith({
    AleraStatusPalette? critical,
    AleraStatusPalette? warning,
    AleraStatusPalette? success,
    AleraStatusPalette? info,
    AleraStatusPalette? neutral,
  }) {
    return AleraStatusColors(
      critical: critical ?? this.critical,
      warning: warning ?? this.warning,
      success: success ?? this.success,
      info: info ?? this.info,
      neutral: neutral ?? this.neutral,
    );
  }

  @override
  AleraStatusColors lerp(
    covariant ThemeExtension<AleraStatusColors>? other,
    double t,
  ) {
    if (other is! AleraStatusColors) return this;
    return AleraStatusColors(
      critical: AleraStatusPalette.lerp(critical, other.critical, t),
      warning: AleraStatusPalette.lerp(warning, other.warning, t),
      success: AleraStatusPalette.lerp(success, other.success, t),
      info: AleraStatusPalette.lerp(info, other.info, t),
      neutral: AleraStatusPalette.lerp(neutral, other.neutral, t),
    );
  }
}
