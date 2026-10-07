import 'package:flutter/material.dart';

import '../../../design_system/widgets/alera_snackbar.dart';
import '../data/reminder_api_data_source.dart';

/// Runs a controller action and reports the outcome in a snackbar.
Future<void> runReminderAction(
  BuildContext context,
  Future<void> Function() operation, {
  String success = 'Reminder updated.',
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await operation();
    showAleraSnackBarOn(messenger, success, type: AleraSnackBarType.success);
  } on ReminderApiFailure catch (error) {
    if (error.statusCode == 401) return;
    showAleraSnackBarOn(
      messenger,
      error.message,
      type: AleraSnackBarType.error,
    );
  }
}
