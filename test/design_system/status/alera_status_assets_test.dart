import 'dart:io';

import 'package:alera/design_system/status/alera_status_assets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// Declared SVG assets must exist on disk and parse.
///
/// This is the CI guarantee that replaces a runtime asset fallback. A renamed
/// or malformed Figma export fails here instead of at runtime.
void main() {
  group('AleraStatusAssets', () {
    test('declares at least one asset', () {
      expect(AleraStatusAssets.all, isNotEmpty);
    });

    test('every declared asset exists on disk', () {
      final List<String> missing = AleraStatusAssets.all
          .where((String path) => !File(path).existsSync())
          .toList();

      expect(
        missing,
        isEmpty,
        reason:
            'Missing status SVG assets: ${missing.join(', ')}. '
            'Check the Figma export and pubspec.yaml asset declarations.',
      );
    });

    test('every declared asset is parseable SVG', () async {
      for (final String path in AleraStatusAssets.all) {
        final String source = await File(path).readAsString();

        await expectLater(
          vg.loadPicture(SvgStringLoader(source), null),
          completes,
          reason: 'Status SVG failed to parse: $path',
        );
      }
    });

    test('is declared under a pubspec asset directory', () {
      final String pubspec = File('pubspec.yaml').readAsStringSync();

      for (final String path in AleraStatusAssets.all) {
        final String directory = '${path.substring(0, path.lastIndexOf('/'))}/';

        expect(
          pubspec,
          contains(directory),
          reason:
              'Asset directory $directory is not declared in pubspec.yaml, '
              'so $path will not be bundled.',
        );
      }
    });
  });
}
