import 'package:flutter/material.dart';

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
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(success)));
  } on ReminderApiFailure catch (error) {
    if (error.statusCode == 401) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error.message)));
  }
}
