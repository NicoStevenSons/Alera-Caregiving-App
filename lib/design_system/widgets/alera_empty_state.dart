import 'package:flutter/material.dart';

import 'alera_svg_icon.dart';

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
    this.padding = const EdgeInsets.symmetric(vertical: 26, horizontal: 24),
  }) : assert(
         (assetPath == null) != (icon == null),
         'Provide exactly one of assetPath or icon.',
       );

  final String? assetPath;
  final IconData? icon;
  final String title;
  final String message;
  final EdgeInsetsGeometry padding;

  static const Color _iconColor = Color(0xFFCFC7E8);
  static const Color _titleColor = Color(0xFFA69BD2);
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
        ],
      ),
    ),
  );
}
