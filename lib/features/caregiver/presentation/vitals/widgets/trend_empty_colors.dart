import 'package:flutter/material.dart';

/// The muted greys the "No active alerts" empty state uses on the alerts
/// page, shared so every part of a trend page reads the same when there's
/// no data (chart, stat row, summary).
abstract final class TrendEmptyColors {
  static const Color icon = Color(0xFFCFC7E8);
  static const Color title = Color(0xFFA69BD2);
  static const Color body = Color(0xFFB5AADB);
  static const Color iconBackground = Color(0xFFF0EBFA);

  /// Desaturates a full-colour SVG badge so it reads as "empty" without
  /// swapping the asset.
  static const ColorFilter desaturate = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);
}
