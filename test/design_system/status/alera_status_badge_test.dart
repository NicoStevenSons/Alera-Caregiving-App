import 'package:alera/design_system/alera_theme.dart';
import 'package:alera/design_system/status/alera_status_badge.dart';
import 'package:alera/design_system/status/alera_status_descriptor.dart';
import 'package:alera/design_system/status/alera_status_glyph.dart';
import 'package:alera/design_system/status/alera_status_icon.dart';
import 'package:alera/design_system/status/alera_status_tone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const AleraStatusDescriptor _lowBattery = AleraStatusDescriptor(
  tone: AleraStatusTone.warning,
  glyph: AleraStatusGlyph.material(Icons.battery_alert),
  label: 'Low battery',
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

Container _container(WidgetTester tester) =>
    tester.widget<Container>(find.byType(Container));

void main() {
  group('AleraStatusBadge', () {
    testWidgets('renders no visible text, only a glyph', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const AleraStatusBadge(descriptor: _lowBattery)),
      );

      expect(find.byType(Text), findsNothing);
      expect(find.byType(AleraStatusIcon), findsOneWidget);
    });

    testWidgets('carries the label as its accessible name', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _host(const AleraStatusBadge(descriptor: _lowBattery)),
      );

      expect(find.bySemanticsLabel('Low battery'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('labelOverride replaces the accessible name', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _host(
          const AleraStatusBadge(
            descriptor: _lowBattery,
            labelOverride: 'Battery critical',
          ),
        ),
      );

      expect(find.bySemanticsLabel('Battery critical'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('fills with the saturated tone colour, not the soft fill', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const AleraStatusBadge(descriptor: _lowBattery)),
      );

      final BoxDecoration decoration =
          _container(tester).decoration as BoxDecoration;
      final AleraStatusPalette expected = AleraStatusColors.light().warning;

      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, expected.foreground);
      expect(decoration.color, isNot(expected.fill));
    });

    testWidgets('resolves dark theme tone colour', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AleraStatusBadge(descriptor: _lowBattery),
          brightness: Brightness.dark,
        ),
      );

      final BoxDecoration decoration =
          _container(tester).decoration as BoxDecoration;
      final AleraStatusPalette expected = AleraStatusColors.dark().warning;

      expect(decoration.color, expected.foreground);
    });

    testWidgets('draws a ring using the given ringColor and ringWidth', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AleraStatusBadge(
            descriptor: _lowBattery,
            ringColor: Colors.black,
            ringWidth: 3,
          ),
        ),
      );

      final BoxDecoration decoration =
          _container(tester).decoration as BoxDecoration;

      expect(decoration.border, Border.all(color: Colors.black, width: 3));
    });

    testWidgets('defaults the ring to the ambient surface colour', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const AleraStatusBadge(descriptor: _lowBattery)),
      );

      final BoxDecoration decoration =
          _container(tester).decoration as BoxDecoration;
      final Color surface = AleraTheme.caregiver(
        ThemeData.light(),
      ).colorScheme.surface;

      expect(decoration.border, Border.all(color: surface, width: 2));
    });

    testWidgets('sizes the container and glyph from diameter', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AleraStatusBadge(descriptor: _lowBattery, diameter: 30),
        ),
      );

      final Container container = _container(tester);
      final AleraStatusIcon icon = tester.widget<AleraStatusIcon>(
        find.byType(AleraStatusIcon),
      );

      expect(container.constraints?.maxWidth, 30);
      expect(container.constraints?.maxHeight, 30);
      expect(icon.size, 18);
    });

    testWidgets('glyph colour defaults to white for contrast', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const AleraStatusBadge(descriptor: _lowBattery)),
      );

      final AleraStatusIcon icon = tester.widget<AleraStatusIcon>(
        find.byType(AleraStatusIcon),
      );

      expect(icon.color, Colors.white);
    });
  });
}
