import 'package:flutter/material.dart';

import '../../../features/caregiver/domain/models/caregiver_reminder.dart';
import '../alera_status_chip.dart';
import '../alera_status_descriptor.dart';
import '../alera_status_glyph.dart';
import '../alera_status_labels.dart';
import '../alera_status_tone.dart';

/// Maps [CaregiverReminderStatus] to an [AleraStatusChip].
///
/// [CaregiverReminderStatus] has three states — `missed`, `upcoming`,
/// `completed` — not the four-state (Pending / Overdue / Completed / Missed)
/// model originally sketched for this domain. There is no separate "overdue"
/// or "snoozed" state here; `upcoming` covers everything not yet due. The
/// richer `ReminderOccurrenceStatus` in `features/reminders/domain` does have
/// `due`/`snoozed`/`completedLate` etc., but that's the patient-side reminder
/// lifecycle model, not what the caregiver feed's `CaregiverReminder` uses —
/// a separate adapter for that model is a follow-up, not this one.
class ReminderStatusChip extends StatelessWidget {
  final CaregiverReminderStatus status;
  final String? labelOverride;
  final AleraStatusChipSize size;

  const ReminderStatusChip(
    this.status, {
    super.key,
    this.labelOverride,
    this.size = AleraStatusChipSize.medium,
  });

  static AleraStatusDescriptor describe(
    CaregiverReminderStatus status,
    BuildContext context,
  ) {
    final AleraStatusLabels labels = AleraStatusLabels.of(context);

    return switch (status) {
      CaregiverReminderStatus.missed => AleraStatusDescriptor(
        tone: AleraStatusTone.critical,
        glyph: const AleraStatusGlyph.material(Icons.alarm),
        label: labels.reminderMissed,
      ),
      CaregiverReminderStatus.upcoming => AleraStatusDescriptor(
        tone: AleraStatusTone.info,
        glyph: const AleraStatusGlyph.material(Icons.event_outlined),
        label: labels.reminderScheduled,
      ),
      CaregiverReminderStatus.completed => AleraStatusDescriptor(
        tone: AleraStatusTone.success,
        glyph: const AleraStatusGlyph.material(Icons.check_circle),
        label: labels.reminderCompleted,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AleraStatusChip(
      descriptor: describe(status, context),
      labelOverride: labelOverride,
      size: size,
    );
  }
}
