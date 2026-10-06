import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/alera_typography.dart';
import '../../../../../design_system/widgets/alera_card.dart';
import '../../../domain/models/caregiver_reminder.dart';

class PatientRemindersSection extends StatelessWidget {
  final List<CaregiverReminder> reminders;
  final VoidCallback onViewAll;
  final ValueChanged<String> onAction;

  const PatientRemindersSection({
    super.key,
    required this.reminders,
    required this.onViewAll,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return AleraCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Reminders', style: AleraTypography.sectionTitle),
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(44, 36),
                ),
                child: const Text(
                  'View all Reminders',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          _NewReminderField(onTap: () => onAction('New reminder')),
          const SizedBox(height: 8),
          if (reminders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No reminders for this patient.'),
            )
          else
            for (final CaregiverReminder reminder in reminders) ...[
              _ReminderCard(reminder: reminder, onAction: onAction),
              if (reminder != reminders.last) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _NewReminderField extends StatelessWidget {
  final VoidCallback onTap;

  const _NewReminderField({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AleraColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'New reminder...',
                  style: TextStyle(color: AleraColors.fieldHint, fontSize: 12),
                ),
              ),
              Icon(Icons.edit, color: AleraColors.fieldHint, size: 17),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final CaregiverReminder reminder;
  final ValueChanged<String> onAction;

  const _ReminderCard({required this.reminder, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final bool missed = reminder.status == CaregiverReminderStatus.missed;
    final Color accent = missed
        ? AleraColors.critical
        : AleraColors.information;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AleraColors.primary.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${missed ? 'Missed' : 'Upcoming'} ${_time(reminder.scheduledAt)}',
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
            style: AleraTypography.body.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: [
              if (missed) ...[
                _ActionButton(label: 'Call', onTap: () => onAction('Call')),
                _ActionButton(
                  label: 'Resolve',
                  onTap: () => onAction('Resolve'),
                ),
              ] else
                _ActionButton(label: 'Remind', onTap: () => onAction('Remind')),
              _ActionButton(
                label: 'View Details',
                onTap: () => onAction('Reminder details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _time(DateTime value) {
    final int hour = value.hour > 12 ? value.hour - 12 : value.hour;
    return '$hour:${value.minute.toString().padLeft(2, '0')}${value.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: FilledButton.tonal(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          foregroundColor: AleraColors.textSecondary,
          backgroundColor: AleraColors.primarySoft,
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}
