import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_typography.dart';
import '../reminder_formatters.dart';

/// Horizontally scrolling strip of days; the selected day is solid primary.
class ReminderDateStrip extends StatefulWidget {
  const ReminderDateStrip({
    super.key,
    required this.today,
    required this.selected,
    required this.onSelected,
    this.markedDays = const {},
  });


  final DateTime today;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  /// Days (midnight, local) that have reminders; they get a small dot.
  final Set<DateTime> markedDays;

  static const daysBefore = 7;
  static const dayCount = 28;
  static const _itemWidth = 50.0;
  static const _gap = 8.0;

  @override
  State<ReminderDateStrip> createState() => _ReminderDateStripState();
}

class _ReminderDateStripState extends State<ReminderDateStrip> {
  late final ScrollController _scroll;

  /// First day shown. Normally a week before today; re-anchored on the
  /// selected day when a date outside the window is picked from the calendar.
  late DateTime _first = widget.today.subtract(
    const Duration(days: ReminderDateStrip.daysBefore),
  );

  bool _inWindow(DateTime day) =>
      !day.isBefore(_first) &&
      day.isBefore(_first.add(const Duration(days: ReminderDateStrip.dayCount)));

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController(initialScrollOffset: _offsetFor(widget.selected));
  }

  @override
  void didUpdateWidget(ReminderDateStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected && !_inWindow(widget.selected)) {
      final today = widget.today;
      final defaultFirst = today.subtract(
        const Duration(days: ReminderDateStrip.daysBefore),
      );
      final todayWindowHolds =
          !widget.selected.isBefore(defaultFirst) &&
          widget.selected.isBefore(
            defaultFirst.add(const Duration(days: ReminderDateStrip.dayCount)),
          );
      setState(() {
        _first = todayWindowHolds
            ? defaultFirst
            : widget.selected.subtract(
                const Duration(days: ReminderDateStrip.daysBefore),
              );
      });
      if (_scroll.hasClients) _scroll.jumpTo(_offsetFor(widget.selected));
    } else if (oldWidget.selected != widget.selected && _scroll.hasClients) {
      _scroll.animateTo(
        _offsetFor(widget.selected),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  double _offsetFor(DateTime day) {
    final index = day.difference(_first).inDays.clamp(
      0,
      ReminderDateStrip.dayCount - 1,
    );
    // Keep a little context (two days) visible to the left.
    final target = (index - 2).clamp(0, ReminderDateStrip.dayCount);
    return target * (ReminderDateStrip._itemWidth + ReminderDateStrip._gap);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strip = ListView.separated(
        key: const Key('reminder-date-strip'),
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: ReminderDateStrip.dayCount,
        separatorBuilder: (_, _) => const SizedBox(width: ReminderDateStrip._gap),
        itemBuilder: (context, index) {
          final day = _first.add(Duration(days: index));
          final normalized = DateTime(day.year, day.month, day.day);
          return _DayChip(
            day: normalized,
            selected: normalized == widget.selected,
            isToday: normalized == widget.today,
            marked: widget.markedDays.contains(normalized),
            onTap: () => widget.onSelected(normalized),
          );
        },
    );
    return SizedBox(height: 66, child: strip);
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.marked,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final bool marked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AleraColors.textPrimary;
    final secondary = selected
        ? Colors.white.withValues(alpha: 0.85)
        : AleraColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: reminderLongDate(day),
      child: Material(
        key: ValueKey('reminder-day-${reminderApiDate(day)}'),
        // White chips lift off the lavender page; today gets a stronger tint
        // so it still reads when it isn't the selected day.
        color: selected
            ? AleraColors.selected
            : isToday
            ? AleraColors.todayTint
            : Colors.white,
        elevation: 0,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: ReminderDateStrip._itemWidth,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  reminderWeekday(day, short: true),
                  style: AleraTypography.body.copyWith(
                    fontSize: 11,
                    color: secondary,
                  ),
                ),
                const SizedBox(height: 0),
                Text(
                  '${day.day}',
                  style: AleraTypography.sectionTitle.copyWith(
                    fontSize: 18,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
