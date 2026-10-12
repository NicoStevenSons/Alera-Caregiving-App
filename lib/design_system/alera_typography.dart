import 'package:flutter/material.dart';

import 'alera_colors.dart';

abstract final class AleraTypography {
  static const TextStyle pageTitle = TextStyle(
    color: AleraColors.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: AleraColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle body = TextStyle(
    color: AleraColors.textSecondary,
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle label = TextStyle(
    color: AleraColors.textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  /// Section/hero headings inside a page (reminder summary, alert detail).
  static const TextStyle heading = TextStyle(
    color: AleraColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  /// Title of a card or tile that leads a block of content.
  static const TextStyle cardTitle = TextStyle(
    color: AleraColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  /// Title inside a compact list row.
  static const TextStyle rowTitle = TextStyle(
    color: AleraColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  /// Emphasised single-line text (menu items, option labels).
  static const TextStyle bodyStrong = TextStyle(
    color: AleraColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodySmall = TextStyle(
    color: AleraColors.textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  /// Secondary line under a title: times, subtitles, helper text.
  static const TextStyle caption = TextStyle(
    color: AleraColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  /// Smallest readable text: timestamps, tiny captions.
  static const TextStyle micro = TextStyle(
    color: AleraColors.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );

  /// Inline validation / failure text.
  static const TextStyle errorText = TextStyle(
    color: AleraColors.critical,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
}
