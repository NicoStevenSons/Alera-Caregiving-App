import 'package:flutter/material.dart';

import 'alera_colors.dart';
import 'alera_spacing.dart';
import 'alera_theme.dart';

/// Alera look for the patient (elderly) app: the caregiver palette and card
/// style, but with larger type, taller tap targets and a more obvious
/// selected tab. Kept in its own file so it does not collide with changes to
/// [AleraTheme].
abstract final class AleraElderlyTheme {
  /// The same purple the caregiver app's buttons use.
  static const Color _buttonPurple = Color(0xFFAE8BEA);
  static const Color _mutedIcon = Color(0xFFB4AEC2);

  /// Minimum height for any tappable control.
  static const double minTapHeight = 56;

  static ThemeData build(ThemeData parent) {
    final ThemeData base = AleraTheme.caregiver(parent);
    final BorderRadius radius = BorderRadius.circular(AleraSpacing.cardRadius);

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: 64,
        titleTextStyle: TextStyle(
          color: AleraColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: _buttonPurple, size: 28),
        actionsIconTheme: IconThemeData(color: _buttonPurple, size: 28),
      ),
      // Every plain Card in the patient screens becomes an Alera card.
      cardTheme: CardThemeData(
        color: AleraColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: AleraColors.primary.withValues(alpha: 0.10),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: radius),
        clipBehavior: Clip.antiAlias,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AleraColors.primary,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        titleTextStyle: TextStyle(
          color: AleraColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: TextStyle(
          color: AleraColors.textSecondary,
          fontSize: 16,
          height: 1.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AleraColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 76,
        indicatorColor: AleraColors.primarySoft,
        indicatorShape: RoundedRectangleBorder(borderRadius: radius),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            size: 30,
            color: states.contains(WidgetState.selected)
                ? AleraColors.primary
                : _mutedIcon,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? AleraColors.primary
                : AleraColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _buttonPurple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _buttonPurple.withValues(alpha: 0.38),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
          minimumSize: const Size(64, minTapHeight),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _buttonPurple,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, minTapHeight),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AleraColors.primary,
          minimumSize: const Size(64, minTapHeight),
          side: const BorderSide(color: AleraColors.primarySoft, width: 1.5),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AleraColors.primary,
          minimumSize: const Size(64, 48),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        contentTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AleraColors.textPrimary,
        ),
      ),
    );
  }
}
