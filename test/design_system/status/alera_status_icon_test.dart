import 'package:alera/design_system/status/alera_status_assets.dart';
import 'package:alera/design_system/status/alera_status_glyph.dart';
import 'package:alera/design_system/status/alera_status_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AleraStatusIcon', () {
    testWidgets('renders a Material icon when the glyph has no asset', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AleraStatusIcon(
            glyph: AleraStatusGlyph.material(Icons.wifi),
            size: 18,
            color: Color(0xFF00794C),
          ),
        ),
      );

      expect(find.byType(SvgPicture), findsNothing);

      final Icon icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.wifi);
      expect(icon.size, 18);
      expect(icon.color, const Color(0xFF00794C));
    });

    testWidgets('renders an SvgPicture when the glyph has an asset', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AleraStatusIcon(
            glyph: AleraStatusGlyph(
              assetPath: AleraStatusAssets.deviceLowBattery,
              fallbackIcon: Icons.battery_alert,
            ),
            size: 20,
            color: Color(0xFF8A5A00),
          ),
        ),
      );

      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('excludes itself from semantics when unlabelled', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _host(
          const AleraStatusIcon(
            glyph: AleraStatusGlyph.material(Icons.wifi_off),
            size: 16,
            color: Color(0xFF71698D),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Offline'), findsNothing);
      handle.dispose();
    });

    testWidgets('announces its semantic label when given one', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _host(
          const AleraStatusIcon(
            glyph: AleraStatusGlyph.material(Icons.wifi_off),
            size: 16,
            color: Color(0xFF71698D),
            semanticLabel: 'Offline',
          ),
        ),
      );

      expect(find.bySemanticsLabel('Offline'), findsOneWidget);
      handle.dispose();
    });
  });
}
