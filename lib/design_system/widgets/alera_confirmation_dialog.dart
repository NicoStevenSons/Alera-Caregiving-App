import 'package:flutter/material.dart';

import '../alera_colors.dart';
import 'alera_button.dart';

/// Icon-circle, centered-copy confirmation dialog (Figma: the "Create
/// patient?" / "Finish setup?" prompts).
///
/// This is a new shared primitive, not yet adopted by the app's other
/// `showDialog<bool>` call sites (reminders, alert detail, device status) —
/// those still use plain [AlertDialog]. It's introduced here, scoped to the
/// Add Patient / patient access flow, and is a candidate to fold those in
/// later rather than something this change forces on unrelated screens.
///
/// Resolves to `true` only when [confirmLabel] is pressed; dismissing any
/// other way (including [cancelLabel]) resolves to `null`/`false`.
Future<bool?> showAleraConfirmationDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  required String cancelLabel,
  required String confirmLabel,
  bool large = false,
  Key? dialogKey,
  Key? cancelKey,
  Key? confirmKey,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      key: dialogKey,
      backgroundColor: AleraColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: large ? 72 : 56,
              height: large ? 72 : 56,
              decoration: const BoxDecoration(
                color: AleraColors.primarySoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: large ? 36 : 28,
                color: AleraColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: large ? 24 : 18,
                fontWeight: large ? FontWeight.w800 : FontWeight.w700,
                color: AleraColors.textPrimary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: large ? 18 : 13,
                height: 1.4,
                color: AleraColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AleraButton(
                    key: cancelKey,
                    label: cancelLabel,
                    variant: AleraButtonVariant.lightPill,
                    height: large ? 56 : 44,
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AleraButton(
                    key: confirmKey,
                    label: confirmLabel,
                    variant: AleraButtonVariant.pill,
                    height: large ? 56 : 44,
                    onPressed: () => Navigator.pop(dialogContext, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
