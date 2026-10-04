import 'package:flutter/material.dart';

import '../domain/models/elderly_reminder.dart';
import 'widgets/elderly_reminders_list.dart';

class ElderlyRemindersPage extends StatelessWidget {
  const ElderlyRemindersPage({
    super.key,
    required this.isLoading,
    required this.reminders,
    required this.busyOccurrenceIds,
    required this.onOpen,
    required this.onComplete,
    required this.onSnooze,
  });

  final bool isLoading;
  final List<ElderlyReminder> reminders;
  final Set<String> busyOccurrenceIds;
  final ValueChanged<ElderlyReminder> onOpen;
  final Future<void> Function(ElderlyReminder reminder) onComplete;
  final Future<void> Function(ElderlyReminder reminder) onSnooze;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey<String>('elderly-reminders'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        ElderlyRemindersList(
          isLoading: isLoading,
          reminders: reminders,
          busyOccurrenceIds: busyOccurrenceIds,
          onTap: onOpen,
          onComplete: onComplete,
          onSnooze: onSnooze,
        ),
      ],
    );
  }
}
