import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../domain/models/caregiver_alert.dart';

/// Central visual contract for caregiver alerts.
///
/// Health/behavior alerts communicate severity through the accent color.
/// Operational alerts use their own category color:
/// - system/connectivity -> blue
/// - battery/power -> purple
abstract final class CaregiverAlertPresentation {
  static Color accentColor(CaregiverAlert alert) {
    return switch (alert.metric) {
      CaregiverAlertMetric.watchBattery => AleraColors.battery,
      CaregiverAlertMetric.system => AleraColors.information,
      CaregiverAlertMetric.heartRate ||
      CaregiverAlertMetric.spo2 ||
      CaregiverAlertMetric.activity ||
      CaregiverAlertMetric.sleep =>
        alert.severity == CaregiverAlertSeverity.critical
            ? AleraColors.critical
            : AleraColors.warning,
    };
  }

  static String badgeAssetPath(CaregiverAlertMetric metric) {
    return switch (metric) {
      CaregiverAlertMetric.heartRate =>
        'alera-figma-assets/assets/icons/mini_status/heart_rate.svg',
      CaregiverAlertMetric.spo2 =>
        'alera-figma-assets/assets/icons/mini_status/spo2.svg',
      CaregiverAlertMetric.activity =>
        'alera-figma-assets/assets/icons/mini_status/activity.svg',
      CaregiverAlertMetric.sleep =>
        'alera-figma-assets/assets/icons/mini_status/sleep.svg',
      CaregiverAlertMetric.watchBattery =>
        'alera-figma-assets/assets/icons/mini_status/battery.svg',
      CaregiverAlertMetric.system =>
        'alera-figma-assets/assets/icons/mini_status/info.svg',
    };
  }

  static String largeIconPath(CaregiverAlertMetric metric) {
    return switch (metric) {
      CaregiverAlertMetric.heartRate =>
        'alera-figma-assets/assets/icons/vitals/heart_rate.svg',
      CaregiverAlertMetric.spo2 =>
        'alera-figma-assets/assets/icons/vitals/spo2.svg',
      CaregiverAlertMetric.activity =>
        'alera-figma-assets/assets/icons/mini_status/activity.svg',
      CaregiverAlertMetric.sleep =>
        'alera-figma-assets/assets/icons/mini_status/sleep.svg',
      CaregiverAlertMetric.watchBattery =>
        'alera-figma-assets/assets/icons/mini_status/battery.svg',
      CaregiverAlertMetric.system =>
        'alera-figma-assets/assets/icons/status/info.svg',
    };
  }

  static String typeLabel(CaregiverAlertMetric metric) {
    return switch (metric) {
      CaregiverAlertMetric.heartRate => 'Heart rate',
      CaregiverAlertMetric.spo2 => 'SpO₂',
      CaregiverAlertMetric.activity => 'Activity',
      CaregiverAlertMetric.sleep => 'Sleep',
      CaregiverAlertMetric.watchBattery => 'Battery',
      CaregiverAlertMetric.system => 'System',
    };
  }
}
