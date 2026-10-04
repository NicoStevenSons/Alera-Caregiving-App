import 'package:flutter/material.dart';

import '../../domain/models/elderly_reminder.dart';
import 'elderly_reminder_card.dart';

class ElderlyRemindersList extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<ElderlyReminder> reminders;
  final Future<void> Function(ElderlyReminder reminder)? onComplete;
  final Future<void> Function(ElderlyReminder reminder)? onSnooze;
  final Set<String> busyOccurrenceIds;
  final void Function(ElderlyReminder reminder)? onTap;
  final VoidCallback? onRetry;

  const ElderlyRemindersList({
    super.key,
    required this.isLoading,
    this.errorMessage,
    required this.reminders,
    this.onComplete,
    this.onSnooze,
    this.busyOccurrenceIds = const <String>{},
    this.onTap,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        key: Key('elderly-reminders-loading'),
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        key: const Key('elderly-reminders-error'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Unable to load reminders',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                key: const Key('elderly-reminders-retry'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (reminders.isEmpty) {
      return const Center(
        key: Key('elderly-reminders-empty'),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_available_rounded, size: 40),
              SizedBox(height: 12),
              Text('No reminders right now'),
            ],
          ),
        ),
      );
    }

    return Column(
      children: reminders
          .map(
            (reminder) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElderlyReminderCard(
                reminder: reminder,
                busy: busyOccurrenceIds.contains(reminder.occurrenceId),
                onTap: () => onTap?.call(reminder),
                onComplete: () => onComplete?.call(reminder),
                onSnooze: () => onSnooze?.call(reminder),
              ),
            ),
          )
          .toList(),
    );
  }
}
