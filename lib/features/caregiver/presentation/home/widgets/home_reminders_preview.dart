import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/alera_typography.dart';
import '../../../../../design_system/widgets/alera_section_card.dart';
import '../../../../../design_system/widgets/alera_button.dart';
import '../../../domain/models/caregiver_reminder.dart';

class HomeRemindersPreview extends StatelessWidget {
  final List<CaregiverReminder> reminders;
  final VoidCallback onViewAll;
  final ValueChanged<String> onAction;
  final bool loading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const HomeRemindersPreview({
    super.key,
    required this.reminders,
    required this.onViewAll,
    required this.onAction,
    this.loading = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AleraSectionCard(
      title: 'Reminders',
      actionLabel: 'View all Reminders',
      onActionPressed: onViewAll,
      child: Column(
        children: [
          if (loading)
            const Padding(
              key: Key('home-reminders-loading'),
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            )
          else if (errorMessage != null)
            Column(
              key: const Key('home-reminders-error'),
              children: [
                Text(errorMessage!, textAlign: TextAlign.center),
                if (onRetry != null)
                  TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            )
          else if (reminders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No reminders today'),
            )
          else
            for (int index = 0; index < reminders.length; index++) ...[
              _Reminder(reminder: reminders[index], onAction: onAction),
              if (index != reminders.length - 1) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _Reminder extends StatelessWidget {
  final CaregiverReminder reminder;
  final ValueChanged<String> onAction;

  const _Reminder({required this.reminder, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final bool missed = reminder.status == CaregiverReminderStatus.missed;
    final Color accent = missed
        ? AleraColors.critical
        : AleraColors.information;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AleraColors.primary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${reminder.statusLabel ?? switch (reminder.status) {
                  CaregiverReminderStatus.missed => 'Missed',
                  CaregiverReminderStatus.upcoming => 'Upcoming',
                  CaregiverReminderStatus.completed => 'Completed',
                }} ${_time(reminder.scheduledAt)}',
            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
          ),
          Text(
            reminder.title,
            style: AleraTypography.label.copyWith(
              color: AleraColors.textPrimary,
            ),
          ),
          Text(
            reminder.description,
            style: AleraTypography.body.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: [
              _Button(
                label: 'Open Reminders',
                onTap: () => onAction('Open Reminders'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _time(DateTime value) {
    final int hour = value.hour == 0
        ? 12
        : value.hour > 12
        ? value.hour - 12
        : value.hour;
    return '$hour:${value.minute.toString().padLeft(2, '0')}${value.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _Button extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _Button({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AleraButton(
      label: label,
      onPressed: onTap,
      variant: AleraButtonVariant.secondary,
      expand: false,
      height: 34,
    );
  }
}
