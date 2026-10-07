import 'package:flutter/material.dart';

import '../../../../../design_system/widgets/alera_empty_state.dart';
import '../../../../../design_system/widgets/alera_section_card.dart';
import '../../../../../design_system/widgets/alera_skeleton.dart';
import '../../../domain/models/caregiver_reminder.dart';
import '../../widgets/caregiver_reminder_row.dart';

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
              CaregiverReminderRow(
                reminder: reminders[index],
                onTap: () => onAction('Open Reminders'),
                onComplete: onComplete,
              ),
              if (index != reminders.length - 1) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}
