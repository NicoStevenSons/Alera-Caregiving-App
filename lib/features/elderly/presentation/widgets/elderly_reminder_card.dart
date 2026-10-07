import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../domain/models/elderly_reminder.dart';
import '../elderly_reminder_style.dart';
import 'elderly_widgets.dart';

class ElderlyReminderCard extends StatelessWidget {
  final ElderlyReminder reminder;
  final VoidCallback? onComplete;
  final VoidCallback? onSnooze;
  final VoidCallback? onTap;
  final bool busy;
  const ElderlyReminderCard({
    super.key,
    required this.reminder,
    this.onComplete,
    this.onSnooze,
    this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final ElderlyReminderStyle style = ElderlyReminderStyle.forCategory(
      reminder.category,
    );
    final Color statusColor = ElderlyReminderStyle.statusColor(reminder.status);
    final bool actionable = _canComplete;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElderlyIconTile(icon: style.icon, color: style.color, size: 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AleraColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _formatDateTime(reminder.dueAt),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AleraColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElderlyStatusChip(
                              label: _formatStatus(reminder.status),
                              color: statusColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (reminder.instructions != null) ...[
                const SizedBox(height: 12),
                Text(
                  reminder.instructions!,
                  style: const TextStyle(
                    fontSize: 17,
                    color: AleraColors.textSecondary,
                  ),
                ),
              ],
              if (actionable) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: busy ? null : onComplete,
                    child: busy
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Complete'),
                  ),
                ),
                if (reminder.snoozeAllowed) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _canSnooze && !busy ? onSnooze : null,
                      child: Text('Snooze ${reminder.defaultSnoozeMinutes} min'),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool get _canComplete =>
      reminder.status != 'COMPLETED' &&
      reminder.status != 'COMPLETED_LATE' &&
      reminder.status != 'CANCELED';

  bool get _canSnooze => _canComplete && reminder.status != 'MISSED';

  static String _formatDateTime(DateTime dateTime) {
    final DateTime local = dateTime.toLocal();

    final int hour = local.hour > 12
        ? local.hour - 12
        : local.hour == 0
        ? 12
        : local.hour;

    final String minute = local.minute.toString().padLeft(2, '0');

    final String period = local.hour >= 12 ? 'PM' : 'AM';

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


/// Compact row for reminders that are finished (completed or canceled).
class ElderlyDoneReminderRow extends StatelessWidget {
  const ElderlyDoneReminderRow({super.key, required this.reminder, this.onTap});

  final ElderlyReminder reminder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ElderlyReminderStyle style = ElderlyReminderStyle.forCategory(
      reminder.category,
    );
    final Color statusColor = ElderlyReminderStyle.statusColor(reminder.status);
    final bool canceled = reminder.status == 'CANCELED';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ElderlyIconTile(
                icon: style.icon,
                color: canceled ? AleraColors.textSecondary : style.color,
                size: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AleraColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ElderlyReminderCard._formatDateTime(reminder.dueAt)} · '
                      '${ElderlyReminderCard._formatStatus(reminder.status)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AleraColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                canceled ? Icons.cancel : Icons.check_circle,
                color: statusColor,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
