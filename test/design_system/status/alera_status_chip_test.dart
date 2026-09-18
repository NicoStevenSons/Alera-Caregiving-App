import 'package:alera/design_system/alera_theme.dart';
import 'package:alera/design_system/status/alera_status_chip.dart';
import 'package:alera/design_system/status/alera_status_descriptor.dart';
import 'package:alera/design_system/status/alera_status_glyph.dart';
import 'package:alera/design_system/status/alera_status_icon.dart';
import 'package:alera/design_system/status/alera_status_tone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const AleraStatusDescriptor _overdue = AleraStatusDescriptor(
  tone: AleraStatusTone.critical,
  glyph: AleraStatusGlyph.material(Icons.alarm),
  label: 'Overdue',
);

Widget _host(Widget child, {Brightness brightness = Brightness.light}) {
  final ThemeData base = brightness == Brightness.dark
      ? ThemeData.dark()
      : ThemeData.light();

  return MaterialApp(
    theme: AleraTheme.caregiver(base),
    home: Scaffold(body: Center(child: child)),
  );
}

DecoratedBox _decoration(WidgetTester tester) =>
    tester.widget<DecoratedBox>(find.byType(DecoratedBox));

void main() {
  group('AleraStatusChip', () {
    testWidgets('shows the descriptor label and glyph', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const AleraStatusChip(descriptor: _overdue)));

      expect(find.text('Overdue'), findsOneWidget);
      expect(find.byType(AleraStatusIcon), findsOneWidget);
    });

    testWidgets('labelOverride replaces the visible text only', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AleraStatusChip(descriptor: _overdue, labelOverride: 'Late'),
        ),
      );

      expect(find.text('Late'), findsOneWidget);
      expect(find.text('Overdue'), findsNothing);
    });

    testWidgets('exposes a single merged semantics node', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(_host(const AleraStatusChip(descriptor: _overdue)));

      expect(find.bySemanticsLabel('Overdue'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('resolves light theme colours from AleraStatusColors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const AleraStatusChip(descriptor: _overdue)));

      final BoxDecoration decoration =
          _decoration(tester).decoration as BoxDecoration;
      final AleraStatusPalette expected = AleraStatusColors.light().critical;

      expect(decoration.color, expected.fill);

      final Icon icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, expected.foreground);

      final Text text = tester.widget<Text>(find.text('Overdue'));
      expect(text.style?.color, expected.foreground);
    });

    testWidgets('resolves dark theme colours from AleraStatusColors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AleraStatusChip(descriptor: _overdue),
          brightness: Brightness.dark,
        ),
      );

      final BoxDecoration decoration =
          _decoration(tester).decoration as BoxDecoration;
      final AleraStatusPalette expected = AleraStatusColors.dark().critical;

      expect(decoration.color, expected.fill);
    });

    testWidgets('small size uses tighter padding and a smaller icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AleraStatusChip(
            descriptor: _overdue,
            size: AleraStatusChipSize.small,
          ),
        ),
      );

      final Padding padding = tester.widget<Padding>(find.byType(Padding));
      final AleraStatusIcon icon = tester.widget<AleraStatusIcon>(
        find.byType(AleraStatusIcon),
      );

      expect(padding.padding, const EdgeInsets.symmetric(horizontal: 8, vertical: 4));
      expect(icon.size, 12);
    });

    testWidgets('medium size uses looser padding and a larger icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const AleraStatusChip(descriptor: _overdue)));

      final Padding padding = tester.widget<Padding>(find.byType(Padding));
      final AleraStatusIcon icon = tester.widget<AleraStatusIcon>(
        find.byType(AleraStatusIcon),
      );

      expect(padding.padding, const EdgeInsets.symmetric(horizontal: 12, vertical: 6));
      expect(icon.size, 14);
    });
  });
}
