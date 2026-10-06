import 'package:flutter/material.dart';

import '../../../design_system/alera_colors.dart';

/// Icon + colour for an elderly reminder category (API string).
class ElderlyReminderStyle {
  const ElderlyReminderStyle(this.icon, this.color);

  final IconData icon;
  final Color color;

  static ElderlyReminderStyle forCategory(String category) {
    switch (category) {
      case 'MEDICATION':
        return const ElderlyReminderStyle(Icons.medication, Color(0xFF8B5DE7));
      case 'HEALTH_CHECK':
        return const ElderlyReminderStyle(Icons.monitor_heart, Color(0xFFE0607E));
      case 'HYDRATION':
        return const ElderlyReminderStyle(Icons.water_drop, Color(0xFF3F9BE8));
      case 'MEAL':
        return const ElderlyReminderStyle(Icons.restaurant, Color(0xFFF08A2E));
      case 'MOBILITY':
        return const ElderlyReminderStyle(Icons.directions_walk, Color(0xFF3DB872));
      case 'APPOINTMENT':
        return const ElderlyReminderStyle(Icons.event, Color(0xFF1FAFA9));
      case 'CHECK_IN':
        return const ElderlyReminderStyle(Icons.chat_bubble, Color(0xFF6F78EE));
      case 'DEVICE_TASK':
        return const ElderlyReminderStyle(Icons.watch, Color(0xFF7B86A0));
      default:
        return const ElderlyReminderStyle(
          Icons.notifications_active,
          AleraColors.primary,
        );
    }
  }

  static Color statusColor(String status) {
    switch (status) {
      case 'DUE':
      case 'SNOOZED':
        return const Color(0xFFD99A00);
      case 'COMPLETED':
      case 'COMPLETED_LATE':
        return const Color(0xFF05A869);
      case 'MISSED':
        return const Color(0xFFE04C5D);
      case 'CANCELED':
        return const Color(0xFF8A8497);
      default:
        return AleraColors.information;
    }
  }
}
