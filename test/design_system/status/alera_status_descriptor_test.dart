import 'package:alera/design_system/alera_theme.dart';
import 'package:alera/design_system/status/alera_status_descriptor.dart';
import 'package:alera/design_system/status/alera_status_glyph.dart';
import 'package:alera/design_system/status/alera_status_labels.dart';
import 'package:alera/design_system/status/alera_status_tone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const AleraStatusDescriptor _overdue = AleraStatusDescriptor(
  tone: AleraStatusTone.critical,
  glyph: AleraStatusGlyph.material(Icons.alarm),
  label: 'Overdue',
);

void main() {
  group('AleraStatusDescriptor', () {
    test('falls back to label for semantics', () {
      expect(_overdue.effectiveSemanticLabel, 'Overdue');
    });

    test('prefers an explicit semantic label', () {
      const AleraStatusDescriptor descriptor = AleraStatusDescriptor(
        tone: AleraStatusTone.critical,
        glyph: AleraStatusGlyph.material(Icons.alarm),
        label: 'Overdue',
        semanticLabel: 'Reminder overdue',
      );

      expect(descriptor.effectiveSemanticLabel, 'Reminder overdue');
    });

    test('equality is by value', () {
      expect(
        _overdue,
        const AleraStatusDescriptor(
          tone: AleraStatusTone.critical,
          glyph: AleraStatusGlyph.material(Icons.alarm),
          label: 'Overdue',
        ),
      );
    });

    test('copyWith overrides only the named field', () {
      final AleraStatusDescriptor updated = _overdue.copyWith(label: 'Missed');

      expect(updated.label, 'Missed');
      expect(updated.tone, AleraStatusTone.critical);
      expect(updated.glyph, _overdue.glyph);
    });

    testWidgets('paletteOf resolves against the ambient theme', (
      WidgetTester tester,
    ) async {
      late AleraStatusPalette palette;

      await tester.pumpWidget(
        MaterialApp(
          theme: AleraTheme.caregiver(ThemeData.light()),
          home: Builder(
            builder: (BuildContext context) {
              palette = _overdue.paletteOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(palette, AleraStatusColors.light().critical);
    });
  });

  group('AleraStatusLabels', () {
    testWidgets('resolves at render time from context', (
      WidgetTester tester,
    ) async {
      late AleraStatusLabels labels;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              labels = AleraStatusLabels.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(labels.deviceLowBattery, 'Low battery');
      expect(labels.vitalElevated, 'Elevated');
      expect(labels.patientPendingAccess, 'Pending access');
    });
  });
}
