import 'package:flutter/material.dart';

import '../../../../../design_system/widgets/alera_button.dart';
import '../../../../../design_system/widgets/alera_empty_state.dart';
import '../../../../../design_system/widgets/alera_section_card.dart';
import '../../../domain/models/caregiver_reminder.dart';
import '../../widgets/caregiver_reminder_row.dart';

/// Today's reminders as quiet rows, with one button to add another.
class PatientRemindersSection extends StatelessWidget {
  final List<CaregiverReminder> reminders;
  final VoidCallback onViewAll;
  final VoidCallback onNewReminder;
  final ValueChanged<CaregiverReminder>? onCompleteReminder;

  const PatientRemindersSection({
    super.key,
    required this.reminders,
    required this.onViewAll,
    required this.onNewReminder,
    this.onCompleteReminder,
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
              CaregiverReminderRow(
                reminder: reminders[i],
                onTap: onViewAll,
                onComplete: onCompleteReminder,
              ),
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
