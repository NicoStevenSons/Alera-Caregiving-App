import 'package:flutter/material.dart';

import '../alera_colors.dart';

/// Alera-styled calendar date picker: a clean white sheet with a soft purple
/// header, rounded day selection and purple actions. Calendar-only (no
/// keyboard-entry toggle).
Future<DateTime?> showAleraDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String helpText = 'Select date',
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: helpText,
    initialEntryMode: DatePickerEntryMode.calendarOnly,
    builder: (context, child) {
      final base = Theme.of(context);
      return Theme(
        data: base.copyWith(
          colorScheme: base.colorScheme.copyWith(
            primary: AleraColors.selected,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AleraColors.textPrimary,
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            headerBackgroundColor: AleraColors.primarySoft,
            headerForegroundColor: AleraColors.primary,
            headerHeadlineStyle: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
            headerHelpStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            dividerColor: Colors.transparent,
            weekdayStyle: const TextStyle(
              color: AleraColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            dayStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            dayForegroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.white
                  : states.contains(WidgetState.disabled)
                  ? AleraColors.textSecondary.withValues(alpha: 0.4)
                  : AleraColors.textPrimary,
            ),
            dayBackgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AleraColors.selected
                  : Colors.transparent,
            ),
            todayForegroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.white
                  : AleraColors.primary,
            ),
            todayBackgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AleraColors.selected
                  : Colors.transparent,
            ),
            todayBorder: const BorderSide(color: AleraColors.selected),
            yearForegroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.white
                  : AleraColors.textPrimary,
            ),
            yearBackgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AleraColors.selected
                  : Colors.transparent,
            ),
            cancelButtonStyle: TextButton.styleFrom(
              foregroundColor: AleraColors.textSecondary,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            confirmButtonStyle: TextButton.styleFrom(
              foregroundColor: AleraColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}
