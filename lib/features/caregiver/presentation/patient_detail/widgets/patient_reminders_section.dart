import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/alera_typography.dart';
import '../../../../../design_system/widgets/alera_button.dart';
import '../../../../../design_system/widgets/alera_card.dart';
import '../../../../../design_system/widgets/alera_empty_state.dart';
import '../../../../../design_system/widgets/alera_section_card.dart';
import '../../../../../design_system/widgets/alera_svg_icon.dart';
import '../../../domain/models/caregiver_reminder.dart';

/// Today's reminders as quiet rows, with one button to add another.
class PatientRemindersSection extends StatelessWidget {
  final List<CaregiverReminder> reminders;
  final VoidCallback onViewAll;
  final VoidCallback onNewReminder;

  const PatientRemindersSection({
    super.key,
    required this.reminders,
    required this.onViewAll,
    required this.onNewReminder,
  });

  @override
  Widget build(BuildContext context) {
    return AleraSectionCard(
      title: 'Reminders',
      actionLabel: 'View all',
      onActionPressed: onViewAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (reminders.isEmpty)
            const AleraEmptyState(
              key: Key('patient-no-reminders'),
              icon: Icons.alarm_off,
              title: 'No reminders today',
              message: 'Add one to help keep the day on track.',
              padding: EdgeInsets.symmetric(vertical: 14),
            )
          else
            for (var i = 0; i < reminders.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _ReminderRow(reminder: reminders[i], onTap: onViewAll),
            ],
          const SizedBox(height: 12),
          AleraButton(
            key: const Key('patient-new-reminder'),
            label: 'Add reminder',
            icon: Icons.add,
            variant: AleraButtonVariant.lightPill,
            height: 42,
            onPressed: onNewReminder,
          ),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final CaregiverReminder reminder;
  final VoidCallback onTap;

  const _ReminderRow({required this.reminder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool missed = reminder.status == CaregiverReminderStatus.missed;
    final bool done = reminder.status == CaregiverReminderStatus.completed;
    final Color accent = missed
        ? AleraColors.critical
        : done
        ? const Color(0xFF05A869)
        : AleraColors.information;
    final String label =
        reminder.statusLabel ??
        (missed ? 'Missed' : done ? 'Completed' : 'Upcoming');

    return AleraCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AleraColors.primarySoft.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: AleraSvgIcon(
                assetPath:
                    'alera-figma-assets/assets/icons/status/reminder.svg',
                width: 26,
                height: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AleraTypography.sectionTitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  '$label · ${_time(reminder.scheduledAt)}',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 22,
            color: AleraColors.mutedChevron,
          ),
        ],
      ),
    );
  }

  String _time(DateTime value) {
    final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    return '$hour:${value.minute.toString().padLeft(2, '0')} '
        '${value.hour >= 12 ? 'PM' : 'AM'}';
  }
}
