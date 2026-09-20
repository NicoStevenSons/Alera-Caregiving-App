import 'package:flutter/material.dart';

import '../alera_colors.dart';
import '../alera_spacing.dart';

class AleraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Fill colour. Defaults to [AleraColors.surface] (white), matching every
  /// existing call site. Pass [AleraColors.surfaceTint] for the lavender-tinted
  /// cards used by selectable options and grouped summaries.
  final Color? color;

  /// Optional hairline border, drawn instead of/alongside the elevation
  /// shadow. Null (the default) matches every existing call site, which rely
  /// on the shadow alone.
  final Color? borderColor;
  final double borderWidth;

  /// Shadow elevation. Defaults to 2, matching every existing call site.
  /// Bordered cards typically pass 0 so the border reads as the only edge.
  final double elevation;

  const AleraCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AleraSpacing.medium),
    this.onTap,
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(padding: padding, child: child);

    return Material(
      color: color ?? AleraColors.surface,
      elevation: elevation,
      shadowColor: AleraColors.primary.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AleraSpacing.cardRadius),
        side: borderColor == null
            ? BorderSide.none
            : BorderSide(color: borderColor!, width: borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
