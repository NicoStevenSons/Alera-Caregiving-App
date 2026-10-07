import 'package:flutter/material.dart';

/// A status glyph: a Figma SVG when one exists, and always a Material icon.
///
/// [fallbackIcon] is required even when [assetPath] is set. It is drawn while
/// the SVG decodes, which removes the blank first frame in long lists, and it
/// is the whole glyph for states that have no authored asset yet.
@immutable
class AleraStatusGlyph {
  /// Asset path, or null when only the Material icon is available.
  final String? assetPath;

  /// Material icon. Placeholder during SVG decode, or the glyph itself.
  final IconData fallbackIcon;

  /// Full-colour Figma icon drawn by `AleraStatusBadge` instead of the tinted
  /// glyph on a solid circle. Chips ignore it and keep using [assetPath] /
  /// [fallbackIcon].
  final String? badgeAssetPath;

  const AleraStatusGlyph({
    this.assetPath,
    required this.fallbackIcon,
    this.badgeAssetPath,
  });

  /// Convenience for a glyph with no authored SVG.
  const AleraStatusGlyph.material(this.fallbackIcon, {this.badgeAssetPath})
    : assetPath = null;

  bool get hasAsset => assetPath != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AleraStatusGlyph &&
        other.assetPath == assetPath &&
        other.fallbackIcon == fallbackIcon &&
        other.badgeAssetPath == badgeAssetPath;
  }

  @override
  int get hashCode => Object.hash(assetPath, fallbackIcon, badgeAssetPath);
}
