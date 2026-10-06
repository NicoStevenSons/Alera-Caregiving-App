import 'package:flutter/material.dart';

import '../alera_colors.dart';
import 'alera_button.dart';

/// The one Alera dialog: white rounded surface, round icon, centred title and
/// message, optional [content] (form fields), inline [errorText], and the
/// pill button pair. Use [showAleraConfirmDialog] for plain yes/no prompts and
/// put this widget inside `showDialog` when the dialog holds inputs.
class AleraDialog extends StatelessWidget {
  const AleraDialog({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.content,
    this.errorText,
    required this.confirmLabel,
    required this.onConfirm,
    this.cancelLabel = 'Back',
    this.onCancel,
    this.destructive = false,
    this.busy = false,
  });

  final IconData icon;
  final String title;
  final String? message;

  /// Inputs or extra copy shown between the message and the buttons.
  final Widget? content;

  /// Inline failure message, shown in the critical colour above the buttons.
  final String? errorText;

  final String confirmLabel;
  final VoidCallback? onConfirm;
  final String cancelLabel;

  /// Defaults to closing the dialog with no result.
  final VoidCallback? onCancel;

  /// Red icon and confirm button, for archive/remove style actions.
  final bool destructive;

  /// Disables both buttons while a request is in flight.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final Color accent = destructive
        ? AleraColors.critical
        : AleraColors.primary;
    return Dialog(
      backgroundColor: AleraColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: destructive
                      ? AleraColors.critical.withValues(alpha: 0.14)
                      : AleraColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 28, color: accent),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AleraColors.textPrimary,
                height: 1.25,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AleraColors.textSecondary,
                ),
              ),
            ],
            if (content != null) ...[const SizedBox(height: 16), content!],
            if (errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                errorText!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AleraColors.critical,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AleraButton(
                    label: cancelLabel,
                    variant: AleraButtonVariant.lightPill,
                    height: 44,
                    onPressed: busy
                        ? null
                        : (onCancel ?? () => Navigator.pop(context)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AleraButton(
                    label: confirmLabel,
                    variant: destructive
                        ? AleraButtonVariant.destructivePill
                        : AleraButtonVariant.pill,
                    height: 44,
                    onPressed: busy ? null : onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Yes/no confirmation. Resolves to true only when the confirm button is
/// pressed; dismissing or pressing the cancel button resolves to false.
Future<bool> showAleraConfirmDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Back',
  bool destructive = false,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AleraDialog(
      icon: icon,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
      onCancel: () => Navigator.pop(dialogContext, false),
      onConfirm: () => Navigator.pop(dialogContext, true),
    ),
  );
  return result ?? false;
}
