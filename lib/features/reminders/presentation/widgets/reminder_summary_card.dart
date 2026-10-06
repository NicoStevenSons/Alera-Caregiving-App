import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/widgets/alera_card.dart';
import '../../../../design_system/widgets/alera_svg_icon.dart';
import '../../domain/reminder_models.dart';
import '../reminder_category_style.dart';
import '../reminder_formatters.dart';
import 'reminder_timeline.dart';

/// Soft gradient summary above the timeline: how many are left and what is
/// next ("3 left today · next at 2:00 PM").
class ReminderSummaryCard extends StatelessWidget {
  const ReminderSummaryCard({
    super.key,
    required this.occurrences,
    required this.isToday,
    this.now,
  });

  /// The selected day's reminders, sorted by time.
  final List<ReminderOccurrence> occurrences;
  final bool isToday;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final actionable = occurrences
        .where((o) => reminderIsActionable(o.status))
        .toList();
    final missed = occurrences
        .where((o) => o.status == ReminderOccurrenceStatus.missed)
        .length;
    final next = actionable.isEmpty ? null : actionable.first;
    final allDone = occurrences.isNotEmpty && actionable.isEmpty && missed == 0;

    // Same layout for every day: big count, label, optional sub-line, and the
    // "Next" chip. Only the wording changes.
    final int count = isToday ? actionable.length : occurrences.length;
    final String headline = isToday ? 'left today' : 'scheduled';
    final String? subline = missed > 0
        ? (missed == 1 ? '1 missed' : '$missed missed')
        : allDone
        ? 'All done'
        : null;

    return AleraCard(
      key: const Key('reminder-summary-card'),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 56,
      child: Row(
        children: [
          Text(
            '$count',
            style: AleraTypography.pageTitle.copyWith(
              fontSize: 28,
              height: 1,
              color: AleraColors.selected,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: AleraTypography.sectionTitle.copyWith(fontSize: 15),
                ),
                if (subline != null)
                  Text(
                    subline,
                    style: TextStyle(
                      color: missed > 0
                          ? AleraColors.critical
                          : AleraColors.successStrong,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          if (next != null) _NextChip(next: next),
        ],
      ),
      ),
    );
  }
}

class _NextChip extends StatelessWidget {
  const _NextChip({required this.next});

  final ReminderOccurrence next;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
      decoration: BoxDecoration(
        color: AleraColors.fieldFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: reminderCategoryTile(next.category),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: AleraSvgIcon(
                assetPath: reminderCategoryAsset(next.category),
                width: 16,
                height: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Next · ${reminderClock(next.scheduledAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AleraColors.selected,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  next.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AleraTypography.label.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
