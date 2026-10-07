import 'package:flutter/material.dart';

import 'alera_button.dart';
import 'alera_svg_icon.dart';
import '../alera_colors.dart';

/// Muted "nothing here" block shared by every empty state in the app
/// (No active alerts, No reminders, ...): a faded icon, a bold lavender title
/// and a one-line explanation.
///
/// Pass either [assetPath] (a Figma SVG) or [icon] (a filled Material icon).
class AleraEmptyState extends StatelessWidget {
  const AleraEmptyState({
    super.key,
    this.assetPath,
    this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.symmetric(vertical: 26, horizontal: 24),
  }) : assert(
         (assetPath == null) != (icon == null),
         'Provide exactly one of assetPath or icon.',
       );

  final String? assetPath;
  final IconData? icon;
  final String title;
  final String message;

  /// Optional pill button under the message (Retry, Add Patient, ...).
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  /// Placeholder for "couldn't load / disconnected" states until a dedicated
  /// icon is drawn. See alera-figma-assets/PLACEHOLDER_ICONS.md.
  static const String errorAsset =
      'alera-figma-assets/assets/icons/status/error.svg';

  static const Color _iconColor = Color(0xFFCFC7E8);
  static const Color _titleColor = AleraColors.emptyTitle;
  static const Color _messageColor = Color(0xFFB5AADB);

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (assetPath != null)
            AleraSvgIcon(
              assetPath: assetPath!,
              width: 48,
              height: 48,
              semanticLabel: title,
            )
          else
            Icon(icon, size: 48, color: _iconColor),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _titleColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _messageColor, fontSize: 12),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            AleraButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: AleraButtonVariant.pill,
              expand: false,
              height: 40,
            ),
          ],
        ],
      ),
    ),
  );
}
