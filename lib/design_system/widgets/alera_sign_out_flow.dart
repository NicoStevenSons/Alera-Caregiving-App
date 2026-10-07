import 'package:flutter/material.dart';

import '../alera_colors.dart';
import 'alera_button.dart';

/// Confirm → blocking "Signing out…" dialog → run [signOut].
///
/// Returns `true` when sign-out completed, `false` when the user cancelled
/// or [signOut] threw (the error is rethrown to the caller via
/// [onError] so it can decide how to report it).
Future<bool> runAleraSignOutFlow(
  BuildContext context, {
  required Future<void> Function() signOut,
  required void Function(Object error) onError,
  bool large = false,
}) async {
  final NavigatorState navigator = Navigator.of(context, rootNavigator: true);

  final bool? confirmed = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => _SignOutConfirmDialog(large: large),
  );
  if (confirmed != true || !context.mounted) return false;

  showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: _SignOutProgressDialog(large: large),
    ),
  );

  try {
    await signOut();
    return true;
  } catch (error) {
    onError(error);
    return false;
  } finally {
    // Close the progress dialog (the session change may have rebuilt the
    // app underneath, but the root navigator still owns the dialog).
    if (navigator.mounted) navigator.pop();
  }
}

class _SignOutConfirmDialog extends StatelessWidget {
  const _SignOutConfirmDialog({required this.large});

  final bool large;

  @override
  Widget build(BuildContext context) {
    final double titleSize = large ? 24 : 18;
    final double bodySize = large ? 18 : 13;
    final double buttonHeight = large ? 56 : 44;

    return Dialog(
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
                Icons.logout,
                size: large ? 36 : 28,
                color: AleraColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sign out?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
                color: AleraColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You will need to sign in again to use Alera.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: bodySize,
                height: 1.4,
                color: AleraColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AleraButton(
                    label: 'Cancel',
                    variant: AleraButtonVariant.lightPill,
                    height: buttonHeight,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AleraButton(
                    label: 'Sign out',
                    variant: AleraButtonVariant.pill,
                    height: buttonHeight,
                    onPressed: () => Navigator.pop(context, true),
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

class _SignOutProgressDialog extends StatelessWidget {
  const _SignOutProgressDialog({required this.large});

  final bool large;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AleraColors.surface,
      surfaceTintColor: Colors.transparent,
      constraints: BoxConstraints(minWidth: 0, maxWidth: large ? 260 : 220),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: large ? 30 : 24,
              child: const CircularProgressIndicator(
                strokeWidth: 3.5,
                color: AleraColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                'Signing out…',
                style: TextStyle(
                  fontSize: large ? 20 : 16,
                  fontWeight: FontWeight.w800,
                  color: AleraColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
