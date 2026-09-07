import 'package:alera/features/caregiver/caregiver_shell.dart';
import 'package:alera/features/caregiver/data/mock/mock_caregiver_repository.dart';
import 'package:alera/features/caregiver/data/alerts/caregiver_alert_controller.dart';
import 'package:alera/features/caregiver/data/api/caregiver_alert_api_data_source.dart';
import 'package:alera/features/caregiver/domain/models/care_recipient.dart';
import 'package:alera/features/caregiver/domain/models/caregiver_alert.dart';
import 'package:alera/features/caregiver/presentation/alerts/caregiver_alert_detail_page.dart';
import 'package:alera/design_system/widgets/alera_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens tapped alert detail and returns to Alerts', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CaregiverShell(repository: MockCaregiverRepository()),
      ),
    );

    await tester.tap(find.text('Alerts'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down).first);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await tester.pumpAndSettle();
    final Finder viewMore = find.text('View Details').first;
    await tester.tap(viewMore);
    await tester.pumpAndSettle();

    expect(find.text('Alert Details'), findsOneWidget);
    expect(find.text('High Heart Rate'), findsWidgets);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('Call'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
    expect(find.text('Acknowledge'), findsOneWidget);
    expect(find.text('Resolve'), findsOneWidget);
    expect(find.text('Add a note about this alert...'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Alerts'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('detail actions provide mock feedback', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CaregiverShell(repository: MockCaregiverRepository()),
      ),
    );
    await tester.tap(find.text('Alerts'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down).first);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await tester.pumpAndSettle();
    final Finder viewMore = find.text('View Details').first;
    await tester.tap(viewMore);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Call'));
    await tester.pump();
    expect(find.text('Call is mock-only for now.'), findsOneWidget);
  });

  testWidgets('prefers live patient name and falls back safely', (
    WidgetTester tester,
  ) async {
    const MockCaregiverRepository repository = MockCaregiverRepository();
    final CareRecipient recipient = repository.getCareRecipients().first;

    await tester.pumpWidget(
      _detailPage(
        alert: _alert(patientDisplayName: 'Live Nana'),
        recipient: recipient,
      ),
    );
    expect(find.textContaining('Live Nana • Triggered'), findsOneWidget);

    await tester.pumpWidget(_detailPage(alert: _alert(), recipient: recipient));
    expect(
      find.textContaining('${recipient.name} • Triggered'),
      findsOneWidget,
    );

    await tester.pumpWidget(_detailPage(alert: _alert()));
    expect(find.textContaining('Unknown patient • Triggered'), findsOneWidget);
  });

  testWidgets('formats old detected timestamps and relative age readably', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _detailPage(alert: _alert(detectedAt: DateTime(2024, 1, 15, 8, 3))),
    );

    expect(find.text('Jan 15, 2024, 8:03 AM'), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'Triggered \d+ years? ago')),
      findsOneWidget,
    );
    expect(find.textContaining('hrs ago'), findsNothing);
  });

  testWidgets('hides duplicate context unless evaluation reason is available', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_detailPage(alert: _alert(description: '')));
    expect(find.text('Alert Details'), findsOneWidget);
    expect(find.text('Current Context'), findsNothing);
    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('Threshold'), findsOneWidget);
    expect(find.text('Duration'), findsOneWidget);

    await tester.pumpWidget(
      _detailPage(
        alert: _alert(description: 'Heart rate exceeded the configured limit.'),
      ),
    );
    expect(find.text('Current Context'), findsOneWidget);
    expect(find.text('Evaluation reason'), findsOneWidget);
    expect(
      find.text('Heart rate exceeded the configured limit.'),
      findsOneWidget,
    );
    expect(find.text('Reading'), findsOneWidget);
  });

  testWidgets('blank required action text is blocked before request', (
    tester,
  ) async {
    final actions = _CountingActions(_alert());
    final controller = CaregiverAlertController(
      loader: _DetailLoader([_alert()]),
      actions: actions,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CaregiverAlertDetailPage(
          alert: _alert(),
          careRecipient: null,
          alertController: controller,
        ),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AleraButton, 'Add Note'), findsNothing);
    await tester.tap(find.byTooltip('Save note'));
    await tester.pump();

    expect(find.text('Note is required.'), findsOneWidget);
    expect(actions.calls, 0);
    controller.dispose();
  });

  testWidgets('notes input submits through the alert action API', (
    tester,
  ) async {
    final actions = _CountingActions(_alert());
    final controller = CaregiverAlertController(
      loader: _DetailLoader([_alert()]),
      actions: actions,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CaregiverAlertDetailPage(
          alert: _alert(),
          careRecipient: null,
          alertController: controller,
        ),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '  Followed up  ');
    await tester.tap(find.byTooltip('Save note'));
    await tester.pumpAndSettle();

    expect(actions.lastNote, 'Followed up');
    expect(find.widgetWithText(AleraButton, 'Add Note'), findsNothing);
    controller.dispose();
  });
}

Widget _detailPage({required CaregiverAlert alert, CareRecipient? recipient}) {
  return MaterialApp(
    home: CaregiverAlertDetailPage(alert: alert, careRecipient: recipient),
  );
}

CaregiverAlert _alert({
  String? patientDisplayName,
  String description = '',
  DateTime? detectedAt,
}) {
  return CaregiverAlert(
    id: 'live-alert',
    careRecipientId: 'live-patient',
    patientDisplayName: patientDisplayName,
    title: 'High Heart Rate',
    description: description,
    severity: CaregiverAlertSeverity.critical,
    metric: CaregiverAlertMetric.heartRate,
    status: CaregiverAlertStatus.active,
    reading: 121,
    threshold: 100,
    unit: 'BPM',
    triggerDuration: null,
    detectedAt: detectedAt ?? DateTime.now().subtract(const Duration(hours: 2)),
    timeline: const [],
  );
}

class _DetailLoader implements CaregiverAlertDataSource {
  final List<CaregiverAlert> alerts;
  const _DetailLoader(this.alerts);
  @override
  Future<List<CaregiverAlert>> fetchAlerts() async => alerts;
}

class _CountingActions implements CaregiverAlertActionDataSource {
  final CaregiverAlert result;
  int calls = 0;
  String? lastNote;
  _CountingActions(this.result);
  Future<CaregiverAlert> _run() async {
    calls++;
    return result;
  }

  @override
  Future<CaregiverAlert> acknowledge(String alertId, {String? note}) => _run();
  @override
  Future<CaregiverAlert> addNote(String alertId, String note) {
    lastNote = note;
    return _run();
  }

  @override
  Future<CaregiverAlert> logIntervention(
    String alertId,
    CaregiverInterventionType interventionType,
    String note,
  ) => _run();
  @override
  Future<CaregiverAlert> markFalseAlarm(String alertId, String reason) =>
      _run();
  @override
  Future<CaregiverAlert> resolve(String alertId, {String? note}) => _run();
}
