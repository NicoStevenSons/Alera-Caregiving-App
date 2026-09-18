import 'package:alera/design_system/alera_theme.dart';
import 'package:alera/design_system/status/alera_status_tone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AleraStatusColors', () {
    test('resolve covers every tone in both brightnesses', () {
      for (final AleraStatusColors tokens in <AleraStatusColors>[
        AleraStatusColors.light(),
        AleraStatusColors.dark(),
      ]) {
        for (final AleraStatusTone tone in AleraStatusTone.values) {
          expect(
            () => tokens.resolve(tone),
            returnsNormally,
            reason: 'Tone $tone has no palette.',
          );
        }
      }
    });

    test('light tones are visually distinct from one another', () {
      final AleraStatusColors tokens = AleraStatusColors.light();
      final Set<int> fills = AleraStatusTone.values
          .map((AleraStatusTone tone) => tokens.resolve(tone).fill.toARGB32())
          .toSet();

      expect(
        fills.length,
        AleraStatusTone.values.length,
        reason: 'Two tones share a fill colour in the light theme.',
      );
    });

    test('dark foregrounds are higher luminance than dark fills', () {
      final AleraStatusColors tokens = AleraStatusColors.dark();

      for (final AleraStatusTone tone in AleraStatusTone.values) {
        final AleraStatusPalette palette = tokens.resolve(tone);

        expect(
          palette.foreground.computeLuminance(),
          greaterThan(palette.fill.computeLuminance()),
          reason:
              'Tone $tone has a foreground no brighter than its fill, which '
              'will read muddy on a dark surface.',
        );
      }
    });

    test('copyWith replaces only the named palette', () {
      final AleraStatusColors tokens = AleraStatusColors.light();
      const AleraStatusPalette replacement = AleraStatusPalette(
        fill: Color(0xFF000000),
        foreground: Color(0xFFFFFFFF),
        border: Color(0xFF123456),
      );

      final AleraStatusColors updated = tokens.copyWith(critical: replacement);

      expect(updated.critical, replacement);
      expect(updated.warning, tokens.warning);
      expect(updated.neutral, tokens.neutral);
    });

    test('lerp at both endpoints returns the endpoint values', () {
      final AleraStatusColors light = AleraStatusColors.light();
      final AleraStatusColors dark = AleraStatusColors.dark();

      expect(light.lerp(dark, 0).critical, light.critical);
      expect(light.lerp(dark, 1).critical, dark.critical);
    });

    test('lerp against a foreign extension returns this', () {
      final AleraStatusColors light = AleraStatusColors.light();

      expect(identical(light.lerp(null, 0.5), light), isTrue);
    });

    testWidgets('of() reads tokens registered by AleraTheme', (
      WidgetTester tester,
    ) async {
      late AleraStatusColors resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: AleraTheme.caregiver(ThemeData.light()),
          home: Builder(
            builder: (BuildContext context) {
              resolved = AleraStatusColors.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.critical, AleraStatusColors.light().critical);
    });

    testWidgets('of() falls back to light tokens without theme wiring', (
      WidgetTester tester,
    ) async {
      late AleraStatusColors resolved;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              resolved = AleraStatusColors.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.warning, AleraStatusColors.light().warning);
    });
  });
}
