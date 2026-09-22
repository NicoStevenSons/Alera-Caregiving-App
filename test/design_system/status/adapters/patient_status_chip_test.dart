import 'package:alera/design_system/status/adapters/patient_status_chip.dart';
import 'package:alera/features/caregiver/domain/models/care_recipient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('PatientStatusChip', () {
    testWidgets('critical renders the critical tone and label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const PatientStatusChip(CareStatus.critical)),
      );

      expect(find.text('Critical'), findsOneWidget);
    });

    testWidgets('stable renders the success tone and label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const PatientStatusChip(CareStatus.stable)),
      );

      expect(find.text('Stable'), findsOneWidget);
    });

    testWidgets('needsAttention renders "Attention needed"', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const PatientStatusChip(CareStatus.needsAttention)),
      );

      expect(find.text('Attention needed'), findsOneWidget);
    });

    testWidgets('warning and needsAttention share a tone but not a label '
        'or icon', (WidgetTester tester) async {
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

      final warning = PatientStatusChip.describe(
        CareStatus.warning,
        capturedContext,
      );
      final needsAttention = PatientStatusChip.describe(
        CareStatus.needsAttention,
        capturedContext,
      );

      expect(warning.tone, needsAttention.tone);
      expect(warning.label, isNot(needsAttention.label));
      expect(warning.glyph, isNot(needsAttention.glyph));
    });

    testWidgets('every CareStatus value has a descriptor', (
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

      for (final CareStatus status in CareStatus.values) {
        expect(
          () => PatientStatusChip.describe(status, capturedContext),
          returnsNormally,
          reason: 'CareStatus.$status has no descriptor.',
        );
      }
    });

    testWidgets('labelOverride replaces the visible label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const PatientStatusChip(
            CareStatus.stable,
            labelOverride: 'Doing well',
          ),
        ),
      );

      expect(find.text('Doing well'), findsOneWidget);
      expect(find.text('Stable'), findsNothing);
    });
  });
}
