import 'package:flutter/material.dart';

import '../alera_colors.dart';
import '../alera_typography.dart';

enum AleraPillVariant { action, filter, label }

class AleraPill extends StatelessWidget {
  final String label;
  final Widget? leading;
  final bool selected;
  final VoidCallback? onTap;
  final AleraPillVariant variant;

  /// Fills the width it's given (label centred) instead of hugging its
  /// content, so a row of pills can share one uniform size.
  final bool expand;

  const AleraPill({
    super.key,
    required this.label,
    this.leading,
    this.selected = false,
    this.onTap,
    this.variant = AleraPillVariant.action,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool filterSelected = variant == AleraPillVariant.filter && selected;
    final Color foreground =
        filterSelected || variant == AleraPillVariant.action
        ? AleraColors.selected
        : AleraColors.textSecondary;
    final Color background = filterSelected
        ? AleraColors.primarySoft
        : variant == AleraPillVariant.label
        ? AleraColors.primarySoft
        : Colors.white;
    const BorderSide border = BorderSide.none;

    return Semantics(
      button: onTap != null,
      selected: variant == AleraPillVariant.filter ? selected : null,
      child: Material(
        color: background,
        elevation: variant == AleraPillVariant.label ? 0 : 1,
        shadowColor: AleraColors.primary.withValues(alpha: 0.10),
        shape: StadiumBorder(side: border),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: expand
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 6)],
                Text(
                  label,
                  style: AleraTypography.label.copyWith(
                    color: foreground,
                    fontSize: variant == AleraPillVariant.label ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
