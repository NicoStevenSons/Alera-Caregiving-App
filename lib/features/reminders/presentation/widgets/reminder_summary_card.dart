import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_typography.dart';
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

    final String headline;
    final String? big;
    if (occurrences.isEmpty) {
      big = null;
      headline = isToday ? 'Nothing scheduled today' : 'Nothing scheduled';
    } else if (allDone) {
      big = null;
      headline = isToday ? 'All done for today' : 'All done';
    } else {
      big = '${actionable.length}';
      headline = isToday ? 'left today' : 'scheduled';
    }

    return Container(
      key: const Key('reminder-summary-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9DDFF), Color(0xFFF7F2FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AleraColors.primary.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (allDone)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.check_circle, size: 40, color: Color(0xFF05A869)),
            ),
          if (big != null) ...[
            Text(
              big,
              style: AleraTypography.pageTitle.copyWith(
                fontSize: 40,
                height: 1,
                color: AleraColors.primary,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: AleraTypography.sectionTitle.copyWith(fontSize: 16),
                ),
                if (missed > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    missed == 1 ? '1 missed' : '$missed missed',
                    style: const TextStyle(
                      color: AleraColors.critical,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (next != null) _NextChip(next: next),
        ],
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
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: reminderCategoryTile(next.category),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: AleraSvgIcon(
                assetPath: reminderCategoryAsset(next.category),
                width: 20,
                height: 20,
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
                    color: AleraColors.primary,
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
