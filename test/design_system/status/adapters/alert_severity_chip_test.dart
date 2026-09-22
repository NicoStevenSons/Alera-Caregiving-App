import 'package:alera/design_system/status/adapters/alert_severity_chip.dart';
import 'package:alera/design_system/status/alera_status_tone.dart';
import 'package:alera/features/caregiver/domain/models/caregiver_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AlertSeverityChip', () {
    testWidgets('critical renders the critical tone and label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const AlertSeverityChip(CaregiverAlertSeverity.critical)),
      );

      expect(find.text('Critical'), findsOneWidget);
      final Icon icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.error);
    });

    testWidgets('warning renders the warning tone and label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const AlertSeverityChip(CaregiverAlertSeverity.warning)),
      );

      expect(find.text('Warning'), findsOneWidget);
      final Icon icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.warning_amber);
    });

    testWidgets('describe() maps every severity to a distinct tone', (
      WidgetTester tester,
    ) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (BuildContext context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        AlertSeverityChip.describe(
          CaregiverAlertSeverity.critical,
          capturedContext,
        ).tone,
        AleraStatusTone.critical,
      );
      expect(
        AlertSeverityChip.describe(
          CaregiverAlertSeverity.warning,
          capturedContext,
        ).tone,
        AleraStatusTone.warning,
      );
    });

    testWidgets('labelOverride replaces the visible label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AlertSeverityChip(
            CaregiverAlertSeverity.critical,
            labelOverride: 'Danger',
          ),
        ),
      );

      expect(find.text('Danger'), findsOneWidget);
      expect(find.text('Critical'), findsNothing);
    });
  });
}
