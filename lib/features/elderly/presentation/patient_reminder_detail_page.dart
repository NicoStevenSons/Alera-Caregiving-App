import 'package:flutter/material.dart';

import '../domain/models/elderly_reminder.dart';
import 'widgets/elderly_reminder_card.dart';

class PatientReminderDetailPage extends StatelessWidget {
  const PatientReminderDetailPage({
    super.key,
    required this.reminder,
    required this.onComplete,
    required this.onSnooze,
  });

  final ElderlyReminder reminder;
  final Future<void> Function() onComplete;
  final Future<void> Function() onSnooze;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder details'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ElderlyReminderCard(
            reminder: reminder,
            onComplete: () async {
              Navigator.of(context).pop();
              await onComplete();
            },
            onSnooze: () async {
              Navigator.of(context).pop();
              await onSnooze();
            },
          ),
        ),
      ),
    );
  }
}
