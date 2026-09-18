import 'package:alera/design_system/alera_theme.dart';
import 'package:alera/design_system/status/alera_badged_avatar.dart';
import 'package:alera/design_system/status/alera_status_badge.dart';
import 'package:alera/design_system/status/alera_status_descriptor.dart';
import 'package:alera/design_system/status/alera_status_glyph.dart';
import 'package:alera/design_system/status/alera_status_tone.dart';
import 'package:alera/design_system/widgets/alera_patient_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

const AleraStatusDescriptor _critical = AleraStatusDescriptor(
  tone: AleraStatusTone.critical,
  glyph: AleraStatusGlyph.material(Icons.error),
  label: 'Critical',
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

void main() {
  group('AleraBadgedAvatar', () {
    testWidgets('composes an AleraPatientAvatar and an AleraStatusBadge', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const AleraBadgedAvatar(name: 'Maria Santos', status: _critical)),
      );

      expect(find.byType(AleraPatientAvatar), findsOneWidget);
      expect(find.byType(AleraStatusBadge), findsOneWidget);
    });

    testWidgets('forwards name, photoUrl and radius to AleraPatientAvatar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AleraBadgedAvatar(
            name: 'Maria Santos',
            photoUrl: 'https://example.com/maria.png',
            radius: 24,
            status: _critical,
          ),
        ),
      );

      final AleraPatientAvatar avatar = tester.widget<AleraPatientAvatar>(
        find.byType(AleraPatientAvatar),
      );

      expect(avatar.name, 'Maria Santos');
      expect(avatar.photoUrl, 'https://example.com/maria.png');
      expect(avatar.radius, 24);
    });

    testWidgets('positions the badge in the bottom-right corner', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const AleraBadgedAvatar(name: 'Maria Santos', status: _critical)),
      );

      final Positioned positioned = tester.widget<Positioned>(
        find.ancestor(
          of: find.byType(AleraStatusBadge),
          matching: find.byType(Positioned),
        ),
      );

      expect(positioned.right, isNotNull);
      expect(positioned.bottom, isNotNull);
      expect(positioned.left, isNull);
      expect(positioned.top, isNull);
      // The badge sits slightly outside the avatar edge, pulled back in by
      // the ring, rather than fully inset.
      expect(positioned.right, -2);
      expect(positioned.bottom, -2);
    });

    testWidgets('scales the badge to ~38% of the avatar diameter', (
      WidgetTester tester,
    ) async {
      // radius 20 -> diameter 40 -> 40 * 0.38 = 15.2, above the 14 floor.
      await tester.pumpWidget(
        _host(
          const AleraBadgedAvatar(
            name: 'Maria Santos',
            radius: 20,
            status: _critical,
          ),
        ),
      );

      final AleraStatusBadge badge = tester.widget<AleraStatusBadge>(
        find.byType(AleraStatusBadge),
      );

      expect(badge.diameter, closeTo(15.2, 0.01));
    });

    testWidgets('clamps the badge diameter on a very small avatar', (
      WidgetTester tester,
    ) async {
      // radius 10 -> diameter 20 -> 20 * 0.38 = 7.6, below the 14 floor.
      await tester.pumpWidget(
        _host(
          const AleraBadgedAvatar(
            name: 'Maria Santos',
            radius: 10,
            status: _critical,
          ),
        ),
      );

      final AleraStatusBadge badge = tester.widget<AleraStatusBadge>(
        find.byType(AleraStatusBadge),
      );

      expect(badge.diameter, 14);
    });

    testWidgets('clamps the badge diameter on a very large avatar', (
      WidgetTester tester,
    ) async {
      // radius 40 -> diameter 80 -> 80 * 0.38 = 30.4, above the 22 ceiling.
      await tester.pumpWidget(
        _host(
          const AleraBadgedAvatar(
            name: 'Maria Santos',
            radius: 40,
            status: _critical,
          ),
        ),
      );

      final AleraStatusBadge badge = tester.widget<AleraStatusBadge>(
        find.byType(AleraStatusBadge),
      );

      expect(badge.diameter, 22);
    });

    testWidgets('defaults the ring to the ambient surface colour', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const AleraBadgedAvatar(name: 'Maria Santos', status: _critical)),
      );

      final AleraStatusBadge badge = tester.widget<AleraStatusBadge>(
        find.byType(AleraStatusBadge),
      );
      final Color surface = AleraTheme.caregiver(
        ThemeData.light(),
      ).colorScheme.surface;

      expect(badge.ringColor, surface);
      expect(badge.ringWidth, 2);
    });

    testWidgets('resolves the ring against the dark theme surface', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AleraBadgedAvatar(name: 'Maria Santos', status: _critical),
          brightness: Brightness.dark,
        ),
      );

      final AleraStatusBadge badge = tester.widget<AleraStatusBadge>(
        find.byType(AleraStatusBadge),
      );
      final Color darkSurface = AleraTheme.caregiver(
        ThemeData.dark(),
      ).colorScheme.surface;

      expect(badge.ringColor, darkSurface);
    });

    testWidgets('forwards an explicit ringColor and ringWidth', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AleraBadgedAvatar(
            name: 'Maria Santos',
            status: _critical,
            ringColor: Colors.black,
            ringWidth: 1.5,
          ),
        ),
      );

      final AleraStatusBadge badge = tester.widget<AleraStatusBadge>(
        find.byType(AleraStatusBadge),
      );

      expect(badge.ringColor, Colors.black);
      expect(badge.ringWidth, 1.5);

      final Positioned positioned = tester.widget<Positioned>(
        find.ancestor(
          of: find.byType(AleraStatusBadge),
          matching: find.byType(Positioned),
        ),
      );
      expect(positioned.right, -1.5);
      expect(positioned.bottom, -1.5);
    });

    testWidgets('forwards a statusLabelOverride to the badge', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AleraBadgedAvatar(
            name: 'Maria Santos',
            status: _critical,
            statusLabelOverride: 'Critical alert',
          ),
        ),
      );

      final AleraStatusBadge badge = tester.widget<AleraStatusBadge>(
        find.byType(AleraStatusBadge),
      );

      expect(badge.labelOverride, 'Critical alert');
    });

    testWidgets('merges avatar and badge semantics into one node', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _host(const AleraBadgedAvatar(name: 'Maria Santos', status: _critical)),
      );

      final SemanticsNode merged = tester.getSemantics(
        find.byType(MergeSemantics),
      );

      expect(merged.label, contains('Maria Santos avatar'));
      expect(merged.label, contains('Critical'));
      // A single merged node, not two separately-announced stops.
      expect(find.bySemanticsLabel('Maria Santos avatar'), findsNothing);
      expect(find.bySemanticsLabel('Critical'), findsNothing);

      handle.dispose();
    });
  });
}
