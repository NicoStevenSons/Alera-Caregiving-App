import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/widgets/alera_pill.dart';
import '../reminder_formatters.dart';

/// Title row at the top of the day's reminder list: the selected date with a
/// calendar icon and dropdown arrow (tap to open the calendar) and a Today
/// pill to jump back.
class ReminderDateHeader extends StatelessWidget {
  const ReminderDateHeader({
    super.key,
    required this.date,
    required this.isToday,
    required this.onPickDate,
    required this.onToday,
  });

  final DateTime date;
  final bool isToday;
  final VoidCallback onPickDate;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              key: const Key('reminder-pick-date'),
              onTap: onPickDate,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      size: 20,
                      color: AleraColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        reminderLongDate(date),
                        key: const Key('reminder-selected-date'),
                        overflow: TextOverflow.ellipsis,
                        style: AleraTypography.pageTitle.copyWith(fontSize: 17),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 22,
                      color: AleraColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AleraPill(
          key: const Key('reminder-today-pill'),
          label: 'Today',
          variant: isToday ? AleraPillVariant.label : AleraPillVariant.action,
          onTap: isToday ? null : onToday,
        ),
      ],
    );
  }
}
