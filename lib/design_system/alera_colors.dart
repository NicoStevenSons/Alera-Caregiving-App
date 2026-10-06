import 'package:flutter/material.dart';

abstract final class AleraColors {
  static const Color primary = Color(0xFF8B5DE7);
  static const Color primarySoft = Color(0xFFE8DDFB);
  static const Color background = Color(0xFFF7F4FF);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF3D3459);
  static const Color textSecondary = Color(0xFF71698D);
  static const Color divider = Color(0xFFEDE8F7);

  static const Color success = Color(0xFF08D887);
  static const Color warning = Color(0xFFFFBE18);
  static const Color critical = Color(0xFFFF6474);
  static const Color information = Color(0xFF55A5FF);
  static const Color battery = Color(0xFFA684FF);

  /// Deeper status accents that stay readable as text on a light tint
  /// (status pills, "Connected", "Stable", "All done").
  static const Color successStrong = Color(0xFF05A869);
  static const Color warningStrong = Color(0xFFD99A00);
  static const Color criticalStrong = Color(0xFFE04C5D);

  /// Pale amber fill for warning banners.
  static const Color warningSoft = Color(0xFFFFF1CC);

  /// Tint for "today" when it is not the selected day.
  static const Color todayTint = Color(0xFFE4D6FF);

  // Form + setup-flow tokens (sampled from the Add Patient Figma frames).
  // Everywhere else a card fill, border, heading or body colour was needed,
  // an existing token (background/divider/primarySoft/textPrimary/
  // textSecondary) was close enough in the source frames to reuse instead
  // of forking a near-duplicate. All setup-flow cards are the same
  // borderless, shadowed white AleraCard used everywhere else in the app -
  // surfaceTint is only for a tinted fill (a selected option, a QR
  // backdrop), never paired with a border.
  static const Color surfaceTint = Color(0xFFF8F5FE);

  // Text-field tokens. These match the caregiver sign-in screen's fields
  // exactly (see aleraInputDecoration in alera_text_field.dart) so every
  // text input in the app - sign-in, Add Patient, patient access - shares
  // one fill/border/hint colour set instead of two near-identical ones.
  static const Color fieldFill = Color(0xFFF7F3FF);
  static const Color fieldBorder = Color(0xFFE0D6F5);
  static const Color fieldHint = Color(0xFFB5A6DB);

  // Softer purple for "selected / active" chrome: the nav bar's current tab,
  // the picked day on Reminders, and the new-reminder button.
  static const Color selected = Color(0xFFAE8BEA);

  /// Muted grey-lavender for chevrons, back arrows and quiet secondary icons.
  static const Color mutedIcon = Color(0xFFB4AEC2);

  /// Slightly lighter variant used for list-row chevrons.
  static const Color mutedChevron = Color(0xFFB7B2C3);

  /// Empty-state title text (matches the faded 'No active alerts' motif).
  static const Color emptyTitle = Color(0xFFA69BD2);
}
