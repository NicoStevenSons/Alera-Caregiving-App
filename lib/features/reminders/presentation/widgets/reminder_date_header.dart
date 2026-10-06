import 'package:flutter/material.dart';

import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/widgets/alera_pill.dart';
import '../reminder_formatters.dart';

/// Title row at the top of the day's reminder list: the selected date and a
/// Today pill to jump back. (Picking another date lives in the date strip.)
class ReminderDateHeader extends StatelessWidget {
  const ReminderDateHeader({
    super.key,
    required this.date,
    required this.isToday,
    required this.onToday,
  });

  final DateTime date;
  final bool isToday;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            reminderLongDate(date),
            key: const Key('reminder-selected-date'),
            overflow: TextOverflow.ellipsis,
            style: AleraTypography.pageTitle.copyWith(fontSize: 17),
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
