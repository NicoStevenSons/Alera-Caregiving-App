import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/widgets/alera_card.dart';
import '../../../../design_system/widgets/alera_pill.dart';
import '../../../../design_system/widgets/alera_svg_icon.dart';
import '../../domain/reminder_models.dart';
import '../reminder_formatters.dart';

const _cardPadding = 12.0;
const _iconTile = 44.0;

bool reminderIsActionable(ReminderOccurrenceStatus status) => switch (status) {
  ReminderOccurrenceStatus.upcoming ||
  ReminderOccurrenceStatus.due ||
  ReminderOccurrenceStatus.snoozed => true,
  _ => false,
};

/// A day's reminders laid out on a vertical rail, one time label per hour
/// that actually has reminders (empty hours are not shown).
class ReminderTimeline extends StatelessWidget {
  const ReminderTimeline({
    super.key,
    required this.occurrences,
    required this.templates,
    required this.isBusy,
    required this.onComplete,
    required this.onOpen,
  });

  /// Already filtered to one day and sorted by time.
  final List<ReminderOccurrence> occurrences;
  final List<ReminderTemplate> templates;
  final bool Function(String occurrenceId) isBusy;
  final ValueChanged<ReminderOccurrence> onComplete;
  final ValueChanged<ReminderOccurrence> onOpen;

  @override
  Widget build(BuildContext context) {
    final templateById = {for (final t in templates) t.id: t};
    return Column(
      children: [
        for (var i = 0; i < occurrences.length; i++)
          _TimelineRow(
            occurrence: occurrences[i],
            template: templateById[occurrences[i].templateId],
            showHour:
                i == 0 ||
                occurrences[i].scheduledAt.toLocal().hour !=
                    occurrences[i - 1].scheduledAt.toLocal().hour,
            isFirst: i == 0,
            isLast: i == occurrences.length - 1,
            busy: isBusy(occurrences[i].id),
            onComplete: () => onComplete(occurrences[i]),
            onOpen: () => onOpen(occurrences[i]),
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.occurrence,
    required this.template,
    required this.showHour,
    required this.isFirst,
    required this.isLast,
    required this.busy,
    required this.onComplete,
    required this.onOpen,
  });

  final ReminderOccurrence occurrence;
  final ReminderTemplate? template;
  final bool showHour;
  final bool isFirst;
  final bool isLast;
  final bool busy;
  final VoidCallback onComplete;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final local = occurrence.scheduledAt.toLocal();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            // Align first: the Row stretches this column to the card's full
            // height, which would otherwise stretch the fixed-height label
            // box too and push the time label below its node.
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: _cardPadding),
                child: SizedBox(
                  height: _iconTile,
                  child: showHour
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            reminderHourLabel(local.hour),
                            style: AleraTypography.body.copyWith(
                              fontSize: 12,
                              color: AleraColors.textSecondary,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: _Rail(
              status: occurrence.status,
              hour: local.hour,
              isFirst: isFirst,
              isLast: isLast,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReminderCard(
                occurrence: occurrence,
                repeatLabel: reminderRepeatLabel(template),
                busy: busy,
                onComplete: onComplete,
                onOpen: onOpen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.status,
    required this.hour,
    required this.isFirst,
    required this.isLast,
  });

  final ReminderOccurrenceStatus status;
  final int hour;
  final bool isFirst;
  final bool isLast;

  // Centre of the node lines up with the centre of the card's title row
  // (and the completion circle on its right).
  static const _nodeSize = 16.0;
  static const _nodeTop = _cardPadding + _iconTile / 2 - _nodeSize / 2;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: isFirst ? _nodeTop + _nodeSize / 2 : 0,
          bottom: isLast ? null : 0,
          height: isLast ? _nodeTop + _nodeSize / 2 : null,
          child: isLast && isFirst
              ? const SizedBox.shrink()
              : Container(width: 2, color: AleraColors.primarySoft),
        ),
        Positioned(top: _nodeTop, child: _node()),
      ],
    );
  }

  Widget _node() {
    final done =
        status == ReminderOccurrenceStatus.completed ||
        status == ReminderOccurrenceStatus.completedLate;
    if (done) {
      return _circle(
        fill: AleraColors.primary,
        child: const Icon(Icons.check, size: 11, color: Colors.white),
      );
    }
    if (status == ReminderOccurrenceStatus.missed) {
      return _circle(
        border: AleraColors.critical,
        child: const Icon(Icons.close, size: 10, color: AleraColors.critical),
      );
    }
    if (status == ReminderOccurrenceStatus.canceled) {
      return _circle(border: AleraColors.divider);
    }
    final night = hour < 6 || hour >= 21;
    return _circle(
      border: AleraColors.primary,
      child: night
          ? const Icon(
              Icons.nightlight_round,
              size: 10,
              color: AleraColors.primary,
            )
          : null,
    );
  }

  Widget _circle({Color? fill, Color? border, Widget? child}) => Container(
    width: _nodeSize,
    height: _nodeSize,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: fill ?? AleraColors.background,
      border: border == null ? null : Border.all(color: border, width: 1.5),
    ),
    child: child == null ? null : Center(child: child),
  );
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.occurrence,
    required this.repeatLabel,
    required this.busy,
    required this.onComplete,
    required this.onOpen,
  });

  final ReminderOccurrence occurrence;
  final String? repeatLabel;
  final bool busy;
  final VoidCallback onComplete;
  final VoidCallback onOpen;

  String? get _statusLabel => switch (occurrence.status) {
    ReminderOccurrenceStatus.missed => 'Missed',
    ReminderOccurrenceStatus.snoozed => 'Snoozed',
    ReminderOccurrenceStatus.canceled => 'Canceled',
    ReminderOccurrenceStatus.completedLate => 'Completed late',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final subtitle =
        occurrence.instructions ??
        reminderTitleCase(occurrence.category.apiValue);
    final status = _statusLabel;
    final muted = occurrence.status == ReminderOccurrenceStatus.canceled;

    return AleraCard(
      key: ValueKey('reminder-occurrence-${occurrence.id}'),
      padding: const EdgeInsets.all(_cardPadding),
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: _iconTile,
            child: Row(
              children: [
                Container(
                  width: _iconTile,
                  height: _iconTile,
                  decoration: BoxDecoration(
                    color: AleraColors.primarySoft.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: muted ? 0.5 : 1,
                      child: AleraSvgIcon(
                        assetPath: reminderCategoryAsset(occurrence.category),
                        width: 28,
                        height: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        occurrence.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AleraTypography.sectionTitle.copyWith(
                          fontSize: 15,
                          decoration: muted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AleraTypography.body.copyWith(
                          fontSize: 12,
                          color: AleraColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _Trailing(
                  occurrence: occurrence,
                  busy: busy,
                  onComplete: onComplete,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Meta(
                icon: Icons.schedule,
                text: reminderClock(occurrence.scheduledAt),
              ),
              if (repeatLabel != null)
                _Meta(icon: Icons.repeat, text: repeatLabel!),
              if (status != null)
                AleraPill(label: status, variant: AleraPillVariant.label),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: AleraColors.primary),
      const SizedBox(width: 4),
      Text(
        text,
        style: AleraTypography.body.copyWith(
          fontSize: 12,
          color: AleraColors.textSecondary,
        ),
      ),
    ],
  );
}

class _Trailing extends StatelessWidget {
  const _Trailing({
    required this.occurrence,
    required this.busy,
    required this.onComplete,
  });

  final ReminderOccurrence occurrence;
  final bool busy;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const SizedBox.square(
        dimension: 30,
        child: Padding(
          padding: EdgeInsets.all(5),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final done =
        occurrence.status == ReminderOccurrenceStatus.completed ||
        occurrence.status == ReminderOccurrenceStatus.completedLate;
    if (done) {
      return const Icon(
        Icons.check_circle,
        size: 30,
        color: AleraColors.primary,
      );
    }
    if (!reminderIsActionable(occurrence.status)) {
      return const SizedBox(width: 30);
    }
    return Semantics(
      button: true,
      label: 'Complete ${occurrence.title}',
      child: InkResponse(
        key: ValueKey('reminder-complete-${occurrence.id}'),
        onTap: onComplete,
        radius: 22,
        // Larger and softer than the timeline node, with a faint check, so
        // it reads as a tappable "mark done" control rather than a marker.
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AleraColors.background,
            border: Border.all(color: AleraColors.primarySoft, width: 2),
          ),
          child: const Icon(
            Icons.check,
            size: 16,
            color: AleraColors.primarySoft,
          ),
        ),
      ),
    );
  }
}
