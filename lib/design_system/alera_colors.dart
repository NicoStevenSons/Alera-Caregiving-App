import 'package:flutter/material.dart';

abstract final class AleraColors {
  static const Color primary = Color(0xFF8B5DE7);
  /// The resting colour of primary buttons: a shade brighter than [primary].
  static const Color primaryMid = Color(0xFFAE8BEA);
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
}
