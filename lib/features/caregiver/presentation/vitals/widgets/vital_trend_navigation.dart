import 'package:flutter/material.dart';

import '../../../data/api/caregiver_activity_trend_api_data_source.dart';
import '../../../data/api/caregiver_sleep_trend_api_data_source.dart';
import '../../../data/api/caregiver_vital_trend_api_data_source.dart';
import '../../../data/api/dto/vital_trend_dto.dart';
import '../caregiver_activity_trend_page.dart';
import '../caregiver_sleep_trend_page.dart';
import '../caregiver_vital_trend_page.dart';

/// Builds the trend page for [metric] so the metric pill row can switch
/// between Heart Rate/SpO2/Activity/Sleep in place (via
/// `Navigator.pushReplacement`) without each trend page needing to know
/// about the others' data sources. Only called for metrics the pill row
/// marks as available - callers should not pass 'Stress' here.
Widget vitalTrendPageFor({
  required String metric,
  required String patientId,
  required String patientName,
}) {
  switch (metric) {
    case 'Activity':
      return CaregiverActivityTrendPage(
        patientId: patientId,
        patientName: patientName,
        dataSource: CaregiverActivityTrendApiDataSource(),
      );
    case 'Sleep':
      return CaregiverSleepTrendPage(
        patientId: patientId,
        patientName: patientName,
        dataSource: CaregiverSleepTrendApiDataSource(),
      );
    case 'SpO2':
    case 'SpO₂':
      return CaregiverVitalTrendPage(
        patientId: patientId,
        patientName: patientName,
        metric: VitalTrendMetric.spo2,
        dataSource: CaregiverVitalTrendApiDataSource(),
      );
    case 'Heart Rate':
      return CaregiverVitalTrendPage(
        patientId: patientId,
        patientName: patientName,
        metric: VitalTrendMetric.heartRate,
        dataSource: CaregiverVitalTrendApiDataSource(),
      );
    default:
      throw ArgumentError.value(metric, 'metric', 'Unsupported trend metric');
  }
}

void switchVitalTrendPage(
  BuildContext context, {
  required String metric,
  required String patientId,
  required String patientName,
}) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute<void>(
      builder: (_) => vitalTrendPageFor(
        metric: metric,
        patientId: patientId,
        patientName: patientName,
      ),
    ),
  );
}

/// Shown when a pill for a metric with no trend page yet (Stress) is
/// tapped - mirrors the message the patient-card tap already shows via
/// `CaregiverShell._openVitalTrend`.
void showVitalTrendUnavailable(BuildContext context, String metric) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text('$metric history is not available yet.')),
    );
}
