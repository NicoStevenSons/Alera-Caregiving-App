import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/widgets/alera_pill.dart';
import '../../../../design_system/widgets/alera_svg_icon.dart';
import '../../domain/reminder_models.dart';
import '../reminder_category_style.dart';
import '../reminder_formatters.dart';

const _cardPadding = 12.0;
const _iconTile = 44.0;

bool reminderIsActionable(ReminderOccurrenceStatus status) => switch (status) {
  ReminderOccurrenceStatus.upcoming ||
  ReminderOccurrenceStatus.due ||
  ReminderOccurrenceStatus.snoozed => true,
  _ => false,
};

/// A day's reminders laid out on a vertical rail. Runs of two or more empty
/// hours collapse into an "N empty hours hidden · Expand" row, and when
/// [now] is given a "NOW" marker sits at the current time.
class ReminderTimeline extends StatefulWidget {
  const ReminderTimeline({
    super.key,
    required this.occurrences,
    required this.templates,
    required this.isBusy,
    required this.onComplete,
    required this.onOpen,
    this.now,
  });

  /// Already filtered to one day and sorted by time.
  final List<ReminderOccurrence> occurrences;
  final List<ReminderTemplate> templates;
  final bool Function(String occurrenceId) isBusy;
  final ValueChanged<ReminderOccurrence> onComplete;
  final ValueChanged<ReminderOccurrence> onOpen;

  /// Local "current time" marker; null hides it (days other than today).
  final DateTime? now;

  @override
  State<ReminderTimeline> createState() => _ReminderTimelineState();
}

sealed class _Entry {
  const _Entry();
}

class _ItemEntry extends _Entry {
  const _ItemEntry(this.occurrence, this.showHour);
  final ReminderOccurrence occurrence;
  final bool showHour;
}

class _NowEntry extends _Entry {
  const _NowEntry(this.time);
  final DateTime time;
}

class _GapEntry extends _Entry {
  const _GapEntry(this.fromHour, this.toHour);
  final int fromHour; // inclusive
  final int toHour; // inclusive
  int get count => toHour - fromHour + 1;
}

class _ReminderTimelineState extends State<ReminderTimeline> {
  List<_Entry> _entries() {
    final items = widget.occurrences;
    final now = widget.now;
    // Merge items and the NOW marker in time order.
    final timed = <({DateTime time, ReminderOccurrence? item})>[
      for (final o in items) (time: o.scheduledAt.toLocal(), item: o),
    ];
    if (now != null) {
      var at = timed.length;
      for (var i = 0; i < timed.length; i++) {
        if (timed[i].time.isAfter(now)) {
          at = i;
          break;
        }
      }
      timed.insert(at, (time: now, item: null));
    }

    final entries = <_Entry>[];
    var previousHour = -1;
    var previousItemHour = -1;
    for (final t in timed) {
      final hour = t.time.hour;
      final emptyFrom = previousHour + 1;
      final emptyTo = hour - 1;
      if (emptyTo - emptyFrom + 1 >= 2) {
        entries.add(_GapEntry(emptyFrom, emptyTo));
      }
      if (t.item == null) {
        entries.add(_NowEntry(t.time));
      } else {
        entries.add(_ItemEntry(t.item!, hour != previousItemHour));
        previousItemHour = hour;
      }
      previousHour = hour;
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final templateById = {for (final t in widget.templates) t.id: t};
    final entries = _entries();
    // First actionable item gets the "lifted" next-up treatment.
    final nextId = widget.occurrences
        .where(
          (o) =>
              reminderIsActionable(o.status) &&
              (widget.now == null || !o.scheduledAt.toLocal().isBefore(widget.now!)),
        )
        .map((o) => o.id)
        .firstOrNull;
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          switch (entries[i]) {
            _ItemEntry(:final occurrence, :final showHour) => _TimelineRow(
              occurrence: occurrence,
              template: templateById[occurrence.templateId],
              showHour: showHour,
              isFirst: i == 0,
              isLast: i == entries.length - 1,
              isNext: occurrence.id == nextId,
              busy: widget.isBusy(occurrence.id),
              onComplete: () => widget.onComplete(occurrence),
              onOpen: () => widget.onOpen(occurrence),
            ),
            _NowEntry(:final time) => _NowRow(
              time: time,
              isFirst: i == 0,
              isLast: i == entries.length - 1,
            ),
            _GapEntry() => _GapRow(
              gap: entries[i] as _GapEntry,
              isFirst: i == 0,
              isLast: i == entries.length - 1,
            ),
          },
      ],
    );
  }
}

/// Rail segment for rows that aren't reminder cards: a continuous line with
/// [node] drawn at [nodeTop].
class _SimpleRail extends StatelessWidget {
  const _SimpleRail({
    required this.isFirst,
    required this.isLast,
    required this.node,
    this.nodeTop = 8,
    this.nodeSize = 14,
  });

  final bool isFirst;
  final bool isLast;
  final Widget node;
  final double nodeTop;
  final double nodeSize;

  @override
  Widget build(BuildContext context) {
    final centre = nodeTop + nodeSize / 2;
    return SizedBox(
      width: 24,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: isFirst ? centre : 0,
            bottom: isLast ? null : 0,
            height: isLast ? centre : null,
            child: isFirst && isLast
                ? const SizedBox.shrink()
                : Container(width: 2, color: AleraColors.primarySoft),
          ),
          Positioned(top: nodeTop, child: node),
        ],
      ),
    );
  }
}

class _NowRow extends StatelessWidget {
  const _NowRow({required this.time, required this.isFirst, required this.isLast});

  final DateTime time;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(width: 44),
          _SimpleRail(
            isFirst: isFirst,
            isLast: isLast,
            nodeTop: 9,
            nodeSize: 12,
            node: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AleraColors.selected,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 2),
              child: Row(
                children: [
                  Container(
                    key: const Key('reminder-now-marker'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AleraColors.selected,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'NOW · ${reminderClock(time)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: _DashedLine()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  // CustomPaint (not LayoutBuilder): this sits inside an IntrinsicHeight row,
  // which cannot measure a LayoutBuilder and would throw.
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 2,
    child: CustomPaint(
      painter: _DashPainter(AleraColors.selected.withValues(alpha: 0.6)),
      size: const Size(double.infinity, 2),
    ),
  );
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 4, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// A quiet, non-interactive marker for a stretch with nothing scheduled.
class _GapRow extends StatelessWidget {
  const _GapRow({
    required this.gap,
    required this.isFirst,
    required this.isLast,
  });

  final _GapEntry gap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(width: 44),
          _SimpleRail(
            isFirst: isFirst,
            isLast: isLast,
            nodeTop: 6,
            nodeSize: 12,
            node: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bedtime,
                size: 10,
                color: AleraColors.mutedIcon,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 2),
              child: Text(
                '${gap.count} empty hours · '
                '${reminderHourLabel(gap.fromHour)} to '
                '${reminderHourLabel(gap.toHour)}',
                key: ValueKey('reminder-gap-${gap.fromHour}'),
                style: AleraTypography.body.copyWith(
                  fontSize: 11,
                  color: AleraColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
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
    required this.isNext,
    required this.busy,
    required this.onComplete,
    required this.onOpen,
  });

  final ReminderOccurrence occurrence;
  final ReminderTemplate? template;
  final bool showHour;
  final bool isFirst;
  final bool isLast;
  final bool isNext;
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
                isNext: isNext,
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
    required this.isNext,
    required this.busy,
    required this.onComplete,
    required this.onOpen,
  });

  final ReminderOccurrence occurrence;
  final String? repeatLabel;
  final bool isNext;
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
    final actionable = reminderIsActionable(occurrence.status);
    final status = _statusLabel;
    final muted = occurrence.status == ReminderOccurrenceStatus.canceled;

    final done =
        occurrence.status == ReminderOccurrenceStatus.completed ||
        occurrence.status == ReminderOccurrenceStatus.completedLate;
    final missed = occurrence.status == ReminderOccurrenceStatus.missed;
    final accent = reminderCategoryColor(occurrence.category);
    final background = muted
        ? Colors.white
        : missed
        ? Color.alphaBlend(
            AleraColors.critical.withValues(alpha: 0.10),
            Colors.white,
          )
        : reminderCategoryWash(occurrence.category, strength: done ? 0.04 : 0.08);
    final content = Column(
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
                    color: muted
                        ? AleraColors.primarySoft.withValues(alpha: 0.6)
                        : reminderCategoryTile(occurrence.category),
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
                text:
                    '${reminderWeekday(occurrence.scheduledAt)} · ${reminderClock(occurrence.scheduledAt)}',
                color: accent,
              ),
              if (repeatLabel != null)
                _Meta(icon: Icons.repeat, text: repeatLabel!, color: accent),
              if (status != null)
                AleraPill(label: status, variant: AleraPillVariant.label),
            ],
          ),
        ],
    );
    return Material(
      key: ValueKey('reminder-occurrence-${occurrence.id}'),
      color: background,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: actionable ? onOpen : null,
        child: Opacity(
          opacity: done ? 0.78 : 1,
          child: Padding(
            padding: const EdgeInsets.all(_cardPadding),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: color),
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
        color: Color(0xFF05A869),
      );
    }
    if (occurrence.status == ReminderOccurrenceStatus.missed) {
      return const Icon(
        Icons.notifications_active,
        size: 28,
        color: AleraColors.critical,
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
