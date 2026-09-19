import 'package:alera/design_system/status/adapters/vital_trend_chip.dart';
import 'package:alera/features/caregiver/data/api/dto/vital_trend_dto.dart'
    show VitalTrendSeverity;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('VitalTrendChip', () {
    testWidgets('info renders Normal with a flat-line glyph', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const VitalTrendChip(VitalTrendSeverity.info)),
      );

      expect(find.text('Normal'), findsOneWidget);
      final Icon icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.remove);
    });

    testWidgets('warning + aboveRange renders Elevated with an up arrow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const VitalTrendChip(
            VitalTrendSeverity.warning,
            direction: VitalTrendDirection.aboveRange,
          ),
        ),
      );

      expect(find.text('Elevated'), findsOneWidget);
      final Icon icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.arrow_upward);
    });

    testWidgets('warning + belowRange renders Low with a down arrow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const VitalTrendChip(
            VitalTrendSeverity.warning,
            direction: VitalTrendDirection.belowRange,
          ),
        ),
      );

      expect(find.text('Low'), findsOneWidget);
      final Icon icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.arrow_downward);
    });

    testWidgets('warning with no direction falls back to a generic Warning', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const VitalTrendChip(VitalTrendSeverity.warning)),
      );

      expect(find.text('Warning'), findsOneWidget);
    });

    testWidgets('critical + aboveRange renders High, distinct from Elevated', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const VitalTrendChip(
            VitalTrendSeverity.critical,
            direction: VitalTrendDirection.aboveRange,
          ),
        ),
      );

      expect(find.text('High'), findsOneWidget);
      expect(find.text('Elevated'), findsNothing);
    });

    testWidgets('critical + belowRange renders "Critically low", distinct '
        'from the warning-tier "Low"', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const VitalTrendChip(
            VitalTrendSeverity.critical,
            direction: VitalTrendDirection.belowRange,
          ),
        ),
      );

      expect(find.text('Critically low'), findsOneWidget);
      expect(find.text('Low'), findsNothing);
    });

    testWidgets('unknown renders a neutral placeholder', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const VitalTrendChip(VitalTrendSeverity.unknown)),
      );

      expect(find.text('Unknown'), findsOneWidget);
    });

    testWidgets(
      'every warning/critical x direction combination has a unique label',
      (WidgetTester tester) async {
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

        final List<String> labels = <String>[];
        for (final VitalTrendSeverity severity in <VitalTrendSeverity>[
          VitalTrendSeverity.warning,
          VitalTrendSeverity.critical,
        ]) {
          for (final VitalTrendDirection? direction in <VitalTrendDirection?>[
            null,
            VitalTrendDirection.aboveRange,
            VitalTrendDirection.belowRange,
          ]) {
            labels.add(
              VitalTrendChip.describe(
                severity,
                capturedContext,
                direction: direction,
              ).label,
            );
          }
        }

        expect(labels.toSet().length, labels.length);
      },
    );
  });
}
