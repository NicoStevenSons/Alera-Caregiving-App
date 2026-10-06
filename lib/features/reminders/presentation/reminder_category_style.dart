import 'package:flutter/material.dart';

import '../../../design_system/alera_colors.dart';
import '../domain/reminder_models.dart';

/// Accent colour per reminder category, used for icon tiles and the soft
/// wash behind reminder cards so the lists read at a glance.
Color reminderCategoryColor(ReminderCategory? category) => switch (category) {
  ReminderCategory.medication => const Color(0xFF8B5DE7),
  ReminderCategory.healthCheck => const Color(0xFFE0607E),
  ReminderCategory.hydration => const Color(0xFF3F9BE8),
  ReminderCategory.meal => const Color(0xFFF08A2E),
  ReminderCategory.mobility => const Color(0xFF3DB872),
  ReminderCategory.appointment => const Color(0xFF1FAFA9),
  ReminderCategory.checkIn => const Color(0xFF6F78EE),
  ReminderCategory.deviceTask => const Color(0xFF7B86A0),
  ReminderCategory.other || null => AleraColors.mutedIcon,
};

/// Very light category tint to use as a card background (on white).
Color reminderCategoryWash(ReminderCategory? category, {double strength = 0.16}) =>
    Color.alphaBlend(
      reminderCategoryColor(category).withValues(alpha: strength),
      Colors.white,
    );

/// Slightly stronger tint for the icon tile.
Color reminderCategoryTile(ReminderCategory? category) =>
    reminderCategoryColor(category).withValues(alpha: 0.24);
