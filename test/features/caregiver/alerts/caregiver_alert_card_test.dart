import 'package:alera/features/caregiver/domain/models/caregiver_alert.dart';
import 'package:alera/features/caregiver/presentation/widgets/caregiver_alert_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders compact and expanded alert variants', (tester) async {
    final alert = CaregiverAlert(
      id: 'alert',
      careRecipientId: 'patient',
      title: 'High Heart Rate',
      description: 'Heart rate exceeded the threshold.',
      severity: CaregiverAlertSeverity.warning,
      metric: CaregiverAlertMetric.heartRate,
      status: CaregiverAlertStatus.active,
      reading: 120,
      threshold: 100,
      unit: 'BPM',
      triggerDuration: Duration(minutes: 5),
      detectedAt: DateTime(2026, 9, 4, 10),
      timeline: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CaregiverAlertCard(
            alert: alert,
            patientName: 'Maria Santos',
            showPatientName: true,
            expanded: true,
            unread: true,
          ),
        ),
      ),
    );

    expect(find.text('Maria Santos'), findsOneWidget);
    expect(find.text('High Heart Rate'), findsOneWidget);
    expect(find.text('View Details'), findsOneWidget);
    expect(find.text('Mark as Seen'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
  });

  testWidgets('chevron toggles without making the body a detail action', (
    tester,
  ) async {
    bool toggleTapped = false;
    final alert = CaregiverAlert(
      id: 'alert',
      careRecipientId: 'patient',
      title: 'Alert',
      description: '',
      severity: CaregiverAlertSeverity.warning,
      metric: CaregiverAlertMetric.heartRate,
      status: CaregiverAlertStatus.active,
      reading: 110,
      threshold: 100,
      unit: 'BPM',
      triggerDuration: Duration(minutes: 1),
      detectedAt: DateTime(2026, 9, 4),
      timeline: [],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CaregiverAlertCard(
            alert: alert,
            onToggleExpanded: () => toggleTapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    expect(toggleTapped, isTrue);
    expect(find.byType(CaregiverAlertCard), findsOneWidget);
    await tester.tap(find.text('Alert'));
    expect(toggleTapped, isTrue);
  });

  testWidgets(
    'battery alert shows battery level and device, not previous avg',
    (tester) async {
      final alert = CaregiverAlert(
        id: 'battery-alert',
        careRecipientId: 'patient',
        conditionKey: 'PHONE_BATTERY_LOW',
        title: 'Patient Phone Battery Low',
        description: 'Phone battery is low.',
        severity: CaregiverAlertSeverity.warning,
        metric: CaregiverAlertMetric.watchBattery,
        status: CaregiverAlertStatus.resolved,
        reading: 12,
        threshold: null,
        unit: '%',
        triggerDuration: null,
        detectedAt: DateTime(2026, 9, 19, 18, 5),
        timeline: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CaregiverAlertCard(alert: alert, expanded: true),
          ),
        ),
      );

      expect(find.text('Battery level'), findsOneWidget);
      expect(find.text('12 %'), findsOneWidget);
      expect(find.text('Device'), findsOneWidget);
      expect(find.text('Patient phone'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
      expect(find.text('Previous Avg'), findsNothing);
    },
  );

  testWidgets('disconnect alert shows device and connection state', (
    tester,
  ) async {
    final alert = CaregiverAlert(
      id: 'disconnect-alert',
      careRecipientId: 'patient',
      conditionKey: 'WATCH_DISCONNECTED',
      title: 'Smartwatch Disconnected',
      description: 'The smartwatch stopped reporting.',
      severity: CaregiverAlertSeverity.warning,
      metric: CaregiverAlertMetric.system,
      status: CaregiverAlertStatus.active,
      reading: 0,
      threshold: null,
      unit: '',
      triggerDuration: null,
      detectedAt: DateTime(2026, 9, 19, 13, 46),
      timeline: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CaregiverAlertCard(alert: alert, expanded: true)),
      ),
    );

    expect(find.text('Device'), findsOneWidget);
    expect(find.text('Smartwatch'), findsOneWidget);
    expect(find.text('Connection'), findsOneWidget);
    expect(find.text('Disconnected'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Previous Avg'), findsNothing);
    expect(find.text('--'), findsNothing);
  });

  testWidgets('inactivity alert uses activity copy without fake averages', (
    tester,
  ) async {
    final alert = CaregiverAlert(
      id: 'activity-alert',
      careRecipientId: 'patient',
      conditionKey: 'INACTIVITY',
      title: 'No Movement Detected',
      description: 'Movement stayed below the configured threshold.',
      severity: CaregiverAlertSeverity.warning,
      metric: CaregiverAlertMetric.activity,
      status: CaregiverAlertStatus.active,
      reading: 0,
      threshold: null,
      unit: 'hr',
      triggerDuration: null,
      detectedAt: DateTime(2026, 9, 19, 12),
      timeline: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CaregiverAlertCard(alert: alert, expanded: true)),
      ),
    );

    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('No movement detected'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Previous Avg'), findsNothing);
  });
}
