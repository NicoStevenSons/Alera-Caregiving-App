import 'package:flutter/material.dart';

import 'alera_colors.dart';
import 'alera_spacing.dart';

abstract final class AleraTheme {
  static ThemeData caregiver(ThemeData parent) {
    final ColorScheme colorScheme = parent.colorScheme.copyWith(
      primary: AleraColors.primary,
      secondary: AleraColors.primarySoft,
      surface: AleraColors.surface,
      error: AleraColors.critical,
      onPrimary: Colors.white,
      onSurface: AleraColors.textPrimary,
    );

    return parent.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AleraColors.background,
      dividerColor: AleraColors.divider,
      inputDecorationTheme: parent.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: AleraColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AleraSpacing.medium,
          vertical: 14,
        ),
        labelStyle: const TextStyle(color: AleraColors.textSecondary),
        helperStyle: const TextStyle(color: AleraColors.textSecondary),
        errorStyle: const TextStyle(color: AleraColors.critical),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AleraSpacing.cardRadius),
          borderSide: const BorderSide(color: AleraColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AleraSpacing.cardRadius),
          borderSide: const BorderSide(color: AleraColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AleraSpacing.cardRadius),
          borderSide: const BorderSide(color: AleraColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AleraSpacing.cardRadius),
          borderSide: const BorderSide(color: AleraColors.critical),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AleraSpacing.cardRadius),
          borderSide: const BorderSide(color: AleraColors.critical, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AleraColors.surface,
        indicatorColor: Colors.transparent,
        elevation: 8,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AleraColors.primary
                : AleraColors.primarySoft,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? AleraColors.primary
                : AleraColors.textSecondary.withValues(alpha: 0.45),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
        }),
      ),
    );
  }
}
