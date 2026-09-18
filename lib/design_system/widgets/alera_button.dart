import 'package:flutter/material.dart';

import '../alera_colors.dart';
import '../alera_typography.dart';

enum AleraButtonVariant { primary, secondary, white, pill, lightPill }

class AleraButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AleraButtonVariant variant;
  final IconData? icon;
  final bool expand;
  final double height;
  final String? semanticLabel;

  const AleraButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AleraButtonVariant.primary,
    this.icon,
    this.expand = true,
    this.height = 40,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bool primary =
        variant == AleraButtonVariant.primary ||
        variant == AleraButtonVariant.pill;

    final bool white = variant == AleraButtonVariant.white;

    final bool pill =
        variant == AleraButtonVariant.pill ||
        variant == AleraButtonVariant.lightPill;

    final ButtonStyle style = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return primary
              ? AleraColors.primary.withValues(alpha: 0.38)
              : white
              ? Colors.white.withValues(alpha: 0.55)
              : AleraColors.divider;
        }

        if (states.contains(WidgetState.pressed)) {
          return primary
              ? const Color(0xFF7449C9)
              : white
              ? const Color(0xFFF4F1FA)
              : const Color(0xFFAFA6D6);
        }

        if (states.contains(WidgetState.hovered)) {
          return primary
              ? const Color(0xFFC3A7F5)
              : white
              ? const Color(0xFFF8F6FC)
              : const Color(0xFFC9C2E0);
        }

        return primary
            ? const Color(0xFFAE8BEA)
            : white
            ? Colors.white
            : const Color(0xFFEDE9F7);
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return primary
              ? Colors.white.withValues(alpha: 0.70)
              : AleraColors.textSecondary.withValues(alpha: 0.50);
        }

        return primary ? Colors.white : const Color(0xFF6B6385);
      }),
      minimumSize: WidgetStateProperty.all(
        Size(expand ? double.infinity : 0, height),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 12),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      elevation: WidgetStateProperty.all(0),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pill ? 20 : 8),
        ),
      ),
      textStyle: WidgetStateProperty.all(
        AleraTypography.label.copyWith(
          fontSize: pill ? 14 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    final Widget button = icon == null
        ? FilledButton(onPressed: onPressed, style: style, child: Text(label))
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 16),
            label: Text(label),
          );

    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: SizedBox(
        width: expand ? double.infinity : null,
        height: height,
        child: button,
      ),
    );
  }
}
