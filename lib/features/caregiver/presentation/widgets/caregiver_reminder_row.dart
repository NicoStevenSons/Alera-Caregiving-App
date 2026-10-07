import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_spacing.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/widgets/alera_svg_icon.dart';
import '../../../reminders/presentation/reminder_category_style.dart';
import '../../../reminders/presentation/reminder_formatters.dart';
import '../../domain/models/caregiver_reminder.dart';

/// The one reminder row used on both Home and the patient page: category
/// icon tile, title, coloured "Status · time" and a chevron. Completing
/// happens from the reminder's detail sheet, not the row.
class CaregiverReminderRow extends StatelessWidget {
  final CaregiverReminder reminder;
  final VoidCallback onTap;
  final ValueChanged<CaregiverReminder>? onComplete;

  const CaregiverReminderRow({
    super.key,
    required this.reminder,
    required this.onTap,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final bool missed = reminder.status == CaregiverReminderStatus.missed;
    final bool done = reminder.status == CaregiverReminderStatus.completed;
    final Color accent = missed
        ? AleraColors.critical
        : done
        ? AleraColors.successStrong
        : AleraColors.information;
    final String label =
        reminder.statusLabel ??
        (missed
            ? 'Missed'
            : done
            ? 'Completed'
            : 'Upcoming');

    return Material(
      color: missed
          ? AleraColors.critical.withValues(alpha: 0.10)
          : reminderCategoryWash(reminder.category),
      borderRadius: BorderRadius.circular(AleraSpacing.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: reminderCategoryTile(reminder.category),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: AleraSvgIcon(
                    assetPath: reminder.category == null
                        ? 'alera-figma-assets/assets/icons/status/reminder.svg'
                        : reminderCategoryAsset(reminder.category!),
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
                      style: AleraTypography.sectionTitle.copyWith(
                        fontSize: 15,
                      ),
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
        ),
      ),
    );
  }

  String _time(DateTime value) {
    final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    return '$hour:${value.minute.toString().padLeft(2, '0')} '
        '${value.hour >= 12 ? 'PM' : 'AM'}';
  }
}
