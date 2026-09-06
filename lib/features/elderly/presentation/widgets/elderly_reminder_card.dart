import 'package:flutter/material.dart';

import '../../domain/models/elderly_reminder.dart';

class ElderlyReminderCard extends StatelessWidget {

  final ElderlyReminder reminder;
  final VoidCallback? onComplete;
  final VoidCallback? onSnooze;


  const ElderlyReminderCard({
  super.key,
  required this.reminder,
  this.onComplete,
  this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.notifications_active,
              color: Colors.purple,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (reminder.instructions != null) ...[
                      const SizedBox(height: 6),
                      Text(
                      reminder.instructions!,
                      ),
                    ],
                  const SizedBox(height: 10),
                  Text(
                    _formatDateTime(
                      reminder.dueAt,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: ElevatedButton(onPressed: reminder.status == 'COMPLETED' ||
                    reminder.status == 'COMPLETED_LATE' ||
                    reminder.status == 'CANCELED'
                    ? null
                    : onComplete, 
                    child: const Text('Complete')
                      )
                    ),

                    if(reminder.snoozeAllowed) ...[
                      const SizedBox(width: 8,),

                      Expanded(child: OutlinedButton(
                        onPressed: reminder.status == 'COMPLETED' ||
                      reminder.status == 'COMPLETED_LATE' ||
                      reminder.status == 'MISSED' ||
                      reminder.status == 'CANCELED'
                      ? null
                      : onSnooze, child: Text('Snooze ${reminder.defaultSnoozeMinutes} min'),
                      )
                    )
                  ]
                ],


                ),

              Text(_formatStatus(reminder.status),
                  style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
  ),),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDateTime(
    DateTime dateTime,
  ) {
    final DateTime local =
        dateTime.toLocal();

    final int hour =
        local.hour > 12
            ? local.hour - 12
            : local.hour == 0
                ? 12
                : local.hour;

    final String minute =
        local.minute
            .toString()
            .padLeft(2, '0');

    final String period =
        local.hour >= 12
            ? 'PM'
            : 'AM';

    return '$hour:$minute $period';
  }

static String _formatStatus(String status) {
  switch (status) {
    case 'UPCOMING':
      return 'Upcoming';

    case 'DUE':
      return 'Due';

    case 'SNOOZED':
      return 'Snoozed';

    case 'COMPLETED':
      return 'Completed';

    case 'COMPLETED_LATE':
      return 'Completed late';

    case 'MISSED':
      return 'Missed';

    case 'CANCELED':
      return 'Canceled';

    default:
      return status;
  }
}

}