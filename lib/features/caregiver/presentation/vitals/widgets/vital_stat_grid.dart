import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/alera_spacing.dart';
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
    return AleraSvgIcon(assetPath: assetPath, width: 32, height: 32);
  }
}

/// The four-tile "Latest / Average / High / Low" style stat row used
/// across the vital, activity and sleep trend pages, sitting in a single
/// card instead of four separate ones.
class VitalStatGrid extends StatelessWidget {
  final List<VitalStatTile> tiles;

  const VitalStatGrid({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return AleraCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AleraSpacing.medium,
        vertical: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: AleraSpacing.small),
            Expanded(child: _Tile(tile: tiles[i])),
          ],
        ],
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
      children: [
        tile.icon,
        const SizedBox(height: 6),
        Text(
          tile.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AleraTypography.body.copyWith(
            fontSize: 11,
            color: AleraColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        // Four across leaves little width per tile, so long values
        // ("2,667 steps") shrink to fit rather than truncating.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            tile.value,
            key: tile.valueKey,
            maxLines: 1,
            style: AleraTypography.sectionTitle.copyWith(fontSize: 15),
          ),
        ),
        if (tile.subtitle != null && tile.subtitle!.isNotEmpty)
          Text(
            tile.subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AleraTypography.body.copyWith(
              fontSize: 9,
              color: AleraColors.textSecondary,
            ),
          ),
      ],
    );
  }
}
