import 'package:flutter/material.dart';

import '../alera_spacing.dart';
import '../alera_typography.dart';
import 'alera_button.dart';

class AleraDialog extends StatelessWidget {
  const AleraDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  final String title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AleraSpacing.cardRadius),
    ),
    title: Text(title, style: AleraTypography.sectionTitle),
    content: content,
    actions: actions,
  );
}

Future<bool> showAleraConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AleraDialog(
      title: title,
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(cancelLabel),
        ),
        AleraButton(
          label: confirmLabel,
          onPressed: () => Navigator.pop(dialogContext, true),
          expand: false,
          variant: destructive
              ? AleraButtonVariant.danger
              : AleraButtonVariant.primary,
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
