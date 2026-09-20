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
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: AleraColors.surfaceTint,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AleraColors.primarySoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 28, color: AleraColors.primary),
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
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AleraColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AleraButton(
                    label: cancelLabel,
                    variant: AleraButtonVariant.lightPill,
                    height: 44,
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AleraButton(
                    label: confirmLabel,
                    variant: AleraButtonVariant.pill,
                    height: 44,
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
