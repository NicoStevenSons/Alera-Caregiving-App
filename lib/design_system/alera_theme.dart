import 'package:flutter/material.dart';

import 'alera_colors.dart';
import 'status/alera_status_tone.dart';

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
      extensions: parent.extensions.values.toList()
        ..add(
          parent.brightness == Brightness.dark
              ? AleraStatusColors.dark()
              : AleraStatusColors.light(),
        ),
      scaffoldBackgroundColor: AleraColors.background,
      dividerColor: AleraColors.divider,
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
