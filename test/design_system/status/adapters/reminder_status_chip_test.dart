import 'package:alera/design_system/status/adapters/reminder_status_chip.dart';
import 'package:alera/design_system/status/alera_status_tone.dart';
import 'package:alera/features/caregiver/domain/models/caregiver_reminder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ReminderStatusChip', () {
    testWidgets('missed renders as critical with an alarm glyph', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const ReminderStatusChip(CaregiverReminderStatus.missed)),
      );

      expect(find.text('Missed'), findsOneWidget);
      final Icon icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.alarm);
    });

    testWidgets('upcoming renders as info / Scheduled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const ReminderStatusChip(CaregiverReminderStatus.upcoming)),
      );

      expect(find.text('Scheduled'), findsOneWidget);
      final Icon icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.event_outlined);
    });

    testWidgets('completed renders as success with a check glyph', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const ReminderStatusChip(CaregiverReminderStatus.completed)),
      );

      expect(find.text('Completed'), findsOneWidget);
      final Icon icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.check_circle);
    });

    testWidgets('describe() maps every status to a distinct tone', (
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

      final Set<AleraStatusTone> tones = CaregiverReminderStatus.values
          .map(
            (CaregiverReminderStatus status) =>
                ReminderStatusChip.describe(status, capturedContext).tone,
          )
          .toSet();

      expect(tones.length, CaregiverReminderStatus.values.length);
    });
  });
}
