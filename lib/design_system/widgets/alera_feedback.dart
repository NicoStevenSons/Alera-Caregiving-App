import 'package:flutter/material.dart';

import '../alera_colors.dart';

enum AleraFeedbackTone { info, success, warning, error }

abstract final class AleraFeedback {
  static void show(
    BuildContext context,
    String message, {
    AleraFeedbackTone tone = AleraFeedbackTone.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _background(tone),
          content: Text(message),
          action: actionLabel == null || onAction == null
              ? null
              : SnackBarAction(label: actionLabel, onPressed: onAction),
        ),
      );
  }

  static void success(BuildContext context, String message) => show(
    context,
    message,
    tone: AleraFeedbackTone.success,
  );

  static void error(BuildContext context, String message) => show(
    context,
    message,
    tone: AleraFeedbackTone.error,
  );

  static Color _background(AleraFeedbackTone tone) => switch (tone) {
    AleraFeedbackTone.info => AleraColors.textPrimary,
    AleraFeedbackTone.success => const Color(0xFF087A55),
    AleraFeedbackTone.warning => const Color(0xFF765500),
    AleraFeedbackTone.error => const Color(0xFF9D2634),
  };
}
