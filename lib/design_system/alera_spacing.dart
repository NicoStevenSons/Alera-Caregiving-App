abstract final class AleraSpacing {
  static const double xSmall = 4;
  static const double small = 8;
  static const double medium = 16;
  static const double large = 24;
  static const double xLarge = 32;

  /// Corner radii: three tokens, nothing in between. Tiny shapes (progress
  /// bars, indicator dots) keep their own 2-5px radius.
  static const double radiusSmall = 8; // chips, inputs, small tiles
  static const double cardRadius = 12; // cards, rows, list tiles
  static const double radiusLarge = 20; // dialogs, sheets, hero cards
  static const double radiusPill = 999; // pills and fully round shapes
}
