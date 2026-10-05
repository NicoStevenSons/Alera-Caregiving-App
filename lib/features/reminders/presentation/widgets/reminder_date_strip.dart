import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_typography.dart';
import '../reminder_formatters.dart';

/// Horizontally scrolling strip of days; the selected day is solid primary.
/// A small dot under a day marks that it has reminders.
class ReminderDateStrip extends StatefulWidget {
  const ReminderDateStrip({
    super.key,
    required this.today,
    required this.selected,
    required this.daysWithReminders,
    required this.onSelected,
  });

  final DateTime today;
  final DateTime selected;
  final Set<DateTime> daysWithReminders;
  final ValueChanged<DateTime> onSelected;

  static const daysBefore = 7;
  static const dayCount = 28;
  static const _itemWidth = 52.0;
  static const _gap = 8.0;

  @override
  State<ReminderDateStrip> createState() => _ReminderDateStripState();
}

class _ReminderDateStripState extends State<ReminderDateStrip> {
  late final ScrollController _scroll;

  DateTime get _first =>
      widget.today.subtract(const Duration(days: ReminderDateStrip.daysBefore));

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController(initialScrollOffset: _offsetFor(widget.selected));
  }

  @override
  void didUpdateWidget(ReminderDateStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected && _scroll.hasClients) {
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
    return SizedBox(
      height: 76,
      child: ListView.separated(
        key: const Key('reminder-date-strip'),
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: ReminderDateStrip.dayCount,
        separatorBuilder: (_, _) => const SizedBox(width: ReminderDateStrip._gap),
        itemBuilder: (context, index) {
          final day = _first.add(Duration(days: index));
          final normalized = DateTime(day.year, day.month, day.day);
          return _DayChip(
            day: normalized,
            selected: normalized == widget.selected,
            isToday: normalized == widget.today,
            hasReminders: widget.daysWithReminders.contains(normalized),
            onTap: () => widget.onSelected(normalized),
          );
        },
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.hasReminders,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final bool hasReminders;
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
        color: selected ? AleraColors.primary : Colors.white,
        elevation: selected ? 2 : 1,
        shadowColor: AleraColors.primary.withValues(alpha: 0.18),
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
                const SizedBox(height: 2),
                Text(
                  '${day.day}',
                  style: AleraTypography.sectionTitle.copyWith(
                    fontSize: 18,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasReminders
                        ? (selected ? Colors.white : AleraColors.primary)
                        : (isToday && !selected
                              ? AleraColors.primarySoft
                              : Colors.transparent),
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
