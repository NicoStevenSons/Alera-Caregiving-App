import 'package:alera/design_system/status/adapters/patient_access_status_chip.dart';
import 'package:alera/features/caregiver/data/api/dto/patient_dto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('PatientAccessStatusChip', () {
    testWidgets('connected renders the success tone and "Active" label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const PatientAccessStatusChip(PatientAccessState.connected)),
      );

      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('invitePending renders "Pending access"', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const PatientAccessStatusChip(PatientAccessState.invitePending),
        ),
      );

      expect(find.text('Pending access'), findsOneWidget);
    });

    testWidgets('notConnected renders "Inactive"', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const PatientAccessStatusChip(PatientAccessState.notConnected)),
      );

      expect(find.text('Inactive'), findsOneWidget);
    });

    testWidgets('every PatientAccessState value has a descriptor', (
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

      for (final PatientAccessState status in PatientAccessState.values) {
        expect(
          () => PatientAccessStatusChip.describe(status, capturedContext),
          returnsNormally,
          reason: 'PatientAccessState.$status has no descriptor.',
        );
      }
    });

    testWidgets('labelOverride replaces the visible label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const PatientAccessStatusChip(
            PatientAccessState.connected,
            labelOverride: 'Signed in',
          ),
        ),
      );

      expect(find.text('Signed in'), findsOneWidget);
      expect(find.text('Active'), findsNothing);
    });
  });
}
