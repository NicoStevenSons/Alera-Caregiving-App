import 'package:flutter/material.dart';

import '../alera_colors.dart';

enum AleraSnackBarType { success, error, info }

/// The one Alera snackbar: a floating white card with a tinted, filled icon
/// tile and the message. Replaces the per-page `SnackBar(content: Text(...))`
/// calls so success, error and info feedback look the same everywhere.
void showAleraSnackBar(
  BuildContext context,
  String message, {
  AleraSnackBarType type = AleraSnackBarType.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 3),
}) => showAleraSnackBarOn(
  ScaffoldMessenger.of(context),
  message,
  type: type,
  actionLabel: actionLabel,
  onAction: onAction,
  duration: duration,
);

/// Same as [showAleraSnackBar] for callers that captured the messenger before
/// an `await` (so no BuildContext is used across the async gap).
void showAleraSnackBarOn(
  ScaffoldMessengerState messenger,
  String message, {
  AleraSnackBarType type = AleraSnackBarType.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 3),
}) {
  final (IconData icon, Color color) = switch (type) {
    AleraSnackBarType.success => (Icons.check_circle, AleraColors.success),
    AleraSnackBarType.error => (Icons.error, AleraColors.critical),
    AleraSnackBarType.info => (Icons.info, AleraColors.information),
  };

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: duration,
        content: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
          decoration: BoxDecoration(
            color: AleraColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AleraColors.primary.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AleraColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
              if (actionLabel != null)
                TextButton(
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                    onAction?.call();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AleraColors.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(actionLabel),
                ),
            ],
          ),
        ),
      ),
    );
}
