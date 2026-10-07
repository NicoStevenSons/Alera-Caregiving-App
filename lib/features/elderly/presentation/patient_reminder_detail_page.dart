import 'package:flutter/material.dart';

import '../../reminders/data/reminder_api_data_source.dart';
import '../../reminders/data/reminder_timeline_controller.dart';
import '../../reminders/presentation/widgets/reminder_history_section.dart';
import '../domain/models/elderly_reminder.dart';
import 'widgets/elderly_reminder_card.dart';

class PatientReminderDetailPage extends StatefulWidget {
  const PatientReminderDetailPage({
    super.key,
    required this.reminder,
    required this.onComplete,
    required this.onSnooze,
    this.eventsDataSource,
  });

  final ElderlyReminder reminder;
  final Future<void> Function() onComplete;
  final Future<void> Function() onSnooze;

  /// Where the reminder's history is read from. When null the history
  /// section is left out (nothing to show it with).
  final ReminderEventsDataSource? eventsDataSource;

  @override
  State<PatientReminderDetailPage> createState() =>
      _PatientReminderDetailPageState();
}

class _PatientReminderDetailPageState extends State<PatientReminderDetailPage> {
  ReminderTimelineController? _history;

  @override
  void initState() {
    super.initState();
    final source = widget.eventsDataSource;
    if (source != null) {
      _history = ReminderTimelineController(
        dataSource: source,
        occurrenceId: widget.reminder.occurrenceId,
      )..load();
    }
  }

  @override
  void dispose() {
    _history?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = _history;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder details'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElderlyReminderCard(
                reminder: widget.reminder,
                onComplete: () async {
                  Navigator.of(context).pop();
                  await widget.onComplete();
                },
                onSnooze: () async {
                  Navigator.of(context).pop();
                  await widget.onSnooze();
                },
              ),
              if (history != null) ...[
                const SizedBox(height: 28),
                ReminderHistorySection(controller: history, elderly: true),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
