import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/alera_typography.dart';
import '../../../../../design_system/widgets/alera_empty_state.dart';
import '../../../../../design_system/widgets/alera_section_card.dart';
import '../../../../../design_system/widgets/alera_skeleton.dart';
import '../../../../../design_system/widgets/alera_button.dart';
import '../../../../../design_system/widgets/alera_svg_icon.dart';
import '../../../../reminders/presentation/reminder_category_style.dart';
import '../../../../reminders/presentation/reminder_formatters.dart';
import '../../../domain/models/caregiver_reminder.dart';

class HomeRemindersPreview extends StatelessWidget {
  final List<CaregiverReminder> reminders;
  final VoidCallback onViewAll;
  final ValueChanged<String> onAction;
  final ValueChanged<CaregiverReminder>? onComplete;
  final bool loading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const HomeRemindersPreview({
    super.key,
    required this.reminders,
    required this.onViewAll,
    required this.onAction,
    this.onComplete,
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
            const Column(
              key: Key('home-reminders-loading'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AleraSkeletonBar(widthFactor: .5, height: 14),
                SizedBox(height: 8),
                AleraSkeletonBar(widthFactor: .8, height: 12),
                SizedBox(height: 12),
              ],
            )
          else if (errorMessage != null)
            AleraEmptyState(
              key: const Key('home-reminders-error'),
              assetPath: AleraEmptyState.errorAsset,
              title: 'Couldn’t load reminders',
              message: errorMessage!,
              actionLabel: onRetry == null ? null : 'Retry',
              onAction: onRetry,
              padding: const EdgeInsets.symmetric(vertical: 18),
            )
          else if (reminders.isEmpty)
            const AleraEmptyState(
              key: Key('home-reminders-empty'),
              icon: Icons.alarm_off,
              title: 'No reminders today',
              message: 'Reminders you schedule will show up here.',
              padding: EdgeInsets.symmetric(vertical: 18),
            )
          else
            for (int index = 0; index < reminders.length; index++) ...[
              _Reminder(
                reminder: reminders[index],
                onAction: onAction,
                onComplete: onComplete,
              ),
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
  final ValueChanged<CaregiverReminder>? onComplete;

  const _Reminder({
    required this.reminder,
    required this.onAction,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final bool missed = reminder.status == CaregiverReminderStatus.missed;
    final Color accent = missed
        ? AleraColors.critical
        : AleraColors.information;
    final Color wash = missed
        ? AleraColors.critical.withValues(alpha: 0.10)
        : reminderCategoryWash(reminder.category);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: missed
            ? Color.alphaBlend(wash, Colors.white)
            : wash,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AleraColors.primary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: reminderCategoryTile(reminder.category),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: AleraSvgIcon(
                assetPath: reminder.category == null
                    ? 'alera-figma-assets/assets/icons/status/reminder.svg'
                    : reminderCategoryAsset(reminder.category!),
                width: 28,
                height: 28,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${reminder.statusLabel ?? switch (reminder.status) {
                        CaregiverReminderStatus.missed => 'Missed',
                        CaregiverReminderStatus.upcoming => 'Upcoming',
                        CaregiverReminderStatus.completed => 'Completed',
                      }} ${_time(reminder.scheduledAt)}',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reminder.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AleraTypography.label.copyWith(
                    color: AleraColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
                if (reminder.description.isNotEmpty)
                  Text(
                    reminder.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AleraTypography.body.copyWith(fontSize: 11),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    if (onComplete != null &&
                        reminder.status == CaregiverReminderStatus.upcoming)
                      AleraButton(
                        key: ValueKey('home-reminder-complete-${reminder.id}'),
                        label: 'Complete',
                        icon: Icons.check,
                        onPressed: () => onComplete!(reminder),
                        expand: false,
                        height: 34,
                      ),
                    _Button(
                      label: 'Open Reminders',
                      onTap: () => onAction('Open Reminders'),
                    ),
                  ],
                ),
              ],
            ),
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
