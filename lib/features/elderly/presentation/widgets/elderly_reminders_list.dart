import 'package:flutter/material.dart';

import '../../domain/models/elderly_reminder.dart';
import 'elderly_reminder_card.dart';

class ElderlyRemindersList extends StatelessWidget {
  final bool isLoading;
  final List<ElderlyReminder> reminders;
  final Future<void> Function(ElderlyReminder reminder)?
    onComplete;
  final Future<void> Function(ElderlyReminder reminder)?
    onSnooze;

  const ElderlyRemindersList({
  super.key,
  required this.isLoading,
  required this.reminders,
  this.onComplete,
  this.onSnooze,
});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (reminders.isEmpty) {
      return const Center(
        child: Text('No reminders'),
      );
    }

    return Column(
      children: reminders
          .map(
            (reminder) => Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: ElderlyReminderCard(
                reminder: reminder,
                onComplete: () {
                onComplete?.call(reminder);
                  },
              onSnooze: () {
              onSnooze?.call(reminder);
                  },
                  ),
            ),
          )
          .toList(),
    );
  }
}