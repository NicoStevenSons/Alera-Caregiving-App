import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'alera_status_glyph.dart';

/// Draws an [AleraStatusGlyph] at [size], tinted [color].
///
/// When the glyph has an SVG, that SVG is the source of truth and the Material
/// icon is rendered during async decode so there is no blank frame. When it has
/// no SVG, the Material icon is the glyph.
///
/// This widget is deliberately not a runtime "asset failed, swap to Material"
/// path. A missing declared asset fails the Flutter build, and a malformed one
/// throws inside `flutter_svg` where `placeholderBuilder` cannot reliably catch
/// it. Both are caught in CI by the asset-existence test instead.
class AleraStatusIcon extends StatelessWidget {
  final AleraStatusGlyph glyph;
  final double size;
  final Color color;

  /// Announced by assistive technology. When null the icon is excluded from the
  /// semantics tree, which is correct when a sibling label already carries the
  /// meaning or when a parent merges semantics.
  final String? semanticLabel;

  const AleraStatusIcon({
    super.key,
    required this.glyph,
    required this.size,
    required this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final String? assetPath = glyph.assetPath;

    if (assetPath == null) {
      return Icon(
        glyph.fallbackIcon,
        size: size,
        color: color,
        semanticLabel: semanticLabel,
      );
    }

    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      placeholderBuilder: (BuildContext context) {
        return Icon(glyph.fallbackIcon, size: size, color: color);
      },
    );
  }
}
