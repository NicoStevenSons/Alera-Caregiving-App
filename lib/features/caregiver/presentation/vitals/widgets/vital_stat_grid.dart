import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/alera_typography.dart';
import '../../../../../design_system/widgets/alera_card.dart';
import '../../../../../design_system/widgets/alera_svg_icon.dart';

/// One tile in a [VitalStatGrid] - an icon plus a label/value pair (e.g.
/// "Average" / "97.4 bpm"). [icon] is a fully-built widget, normally a
/// [VitalStatAssetIcon].
class VitalStatTile {
  final String label;
  final String value;
  final String? subtitle;
  final Widget icon;

  /// Optional key for the value [Text], so a specific tile (e.g. "the
  /// latest reading") stays findable in tests even if its wording changes.
  final Key? valueKey;

  const VitalStatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.subtitle,
    this.valueKey,
  });
}

/// A stat tile icon built from one of Alera's own figma asset SVGs rather
/// than a hand-picked Material icon. Pass a real `mini_status/` asset path
/// where one exists (e.g. the metric's own icon for a "Latest" tile); for
/// a concept that doesn't have a dedicated icon yet (Average/High/Low),
/// pass one of the `mini_status/stat_*.svg` placeholders - each file is a
/// stand-in copy of an existing approved asset, so swapping in the real
/// icon later is just replacing that file's contents, no code changes.
class VitalStatAssetIcon extends StatelessWidget {
  final String assetPath;

  const VitalStatAssetIcon({super.key, required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return AleraSvgIcon(assetPath: assetPath, width: 36, height: 36);
  }
}

/// The four-tile "Latest / Average / High / Low" style stat grid used
/// across the vital, activity and sleep trend pages, sitting in a single
/// card instead of four separate ones.
class VitalStatGrid extends StatelessWidget {
  final List<VitalStatTile> tiles;

  const VitalStatGrid({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return AleraCard(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 1.45,
        children: [for (final tile in tiles) _Tile(tile: tile)],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final VitalStatTile tile;

  const _Tile({required this.tile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        tile.icon,
        const SizedBox(height: 8),
        Text(
          tile.label,
          style: AleraTypography.body.copyWith(
            fontSize: 12,
            color: AleraColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          tile.value,
          key: tile.valueKey,
          style: AleraTypography.sectionTitle.copyWith(fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
        if (tile.subtitle != null)
          Text(
            tile.subtitle!,
            style: AleraTypography.body.copyWith(
              fontSize: 10,
              color: AleraColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
