import 'package:flutter/material.dart';

import '../../../design_system/alera_colors.dart';

/// Scrolling-wheel time picker (hour / minute / AM-PM), modelled on the
/// phone's clock app rather than Material's dial. Lives inline on the page;
/// [onChanged] fires as the wheels settle.
class ReminderTimeWheel extends StatefulWidget {
  const ReminderTimeWheel({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final TimeOfDay initial;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  State<ReminderTimeWheel> createState() => _ReminderTimeWheelState();
}

class _ReminderTimeWheelState extends State<ReminderTimeWheel> {
  static const _itemExtent = 46.0;
  static const _visibleItems = 3;

  late int _hour12; // 1..12
  late int _minute; // 0..59
  late bool _pm;

  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;
  late final FixedExtentScrollController _periodController;

  @override
  void initState() {
    super.initState();
    final hour = widget.initial.hour;
    _hour12 = hour % 12 == 0 ? 12 : hour % 12;
    _minute = widget.initial.minute;
    _pm = hour >= 12;
    _hourController = FixedExtentScrollController(initialItem: _hour12 - 1);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
    _periodController = FixedExtentScrollController(initialItem: _pm ? 1 : 0);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  void _changed(VoidCallback update) {
    setState(update);
    widget.onChanged(
      TimeOfDay(hour: (_hour12 % 12) + (_pm ? 12 : 0), minute: _minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _itemExtent * _visibleItems,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AleraColors.primary.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Highlight band behind the centred (selected) row.
          IgnorePointer(
            child: Container(
              height: _itemExtent,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AleraColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _Wheel(
                  key: const Key('reminder-time-hour'),
                  controller: _hourController,
                  looping: true,
                  count: 12,
                  label: (i) => '${i + 1}',
                  selected: _hour12 - 1,
                  suffix: 'h',
                  onChanged: (i) => _changed(() => _hour12 = i + 1),
                ),
              ),
              Expanded(
                child: _Wheel(
                  key: const Key('reminder-time-minute'),
                  controller: _minuteController,
                  looping: true,
                  count: 60,
                  label: (i) => i.toString().padLeft(2, '0'),
                  selected: _minute,
                  suffix: 'min',
                  onChanged: (i) => _changed(() => _minute = i),
                ),
              ),
              Expanded(
                child: _Wheel(
                  key: const Key('reminder-time-period'),
                  controller: _periodController,
                  looping: false,
                  count: 2,
                  label: (i) => i == 0 ? 'AM' : 'PM',
                  selected: _pm ? 1 : 0,
                  onChanged: (i) => _changed(() => _pm = i == 1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    super.key,
    required this.controller,
    required this.looping,
    required this.count,
    required this.label,
    required this.selected,
    required this.onChanged,
    this.suffix,
  });

  final FixedExtentScrollController controller;
  final bool looping;
  final int count;
  final String Function(int index) label;
  final int selected;
  final ValueChanged<int> onChanged;
  final String? suffix;

  Widget _item(int index) {
    final isSelected = index == selected;
    return Center(
      child: Text.rich(
        TextSpan(
          text: label(index),
          children: [
            if (isSelected && suffix != null)
              TextSpan(
                text: ' $suffix',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        style: TextStyle(
          fontSize: isSelected ? 26 : 20,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          color: isSelected
              ? AleraColors.selected
              : AleraColors.textSecondary.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final delegate = looping
        ? ListWheelChildLoopingListDelegate(
            children: [for (var i = 0; i < count; i++) _item(i)],
          )
        : ListWheelChildListDelegate(
            children: [for (var i = 0; i < count; i++) _item(i)],
          );
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: _ReminderTimeWheelState._itemExtent,
      physics: const FixedExtentScrollPhysics(),
      perspective: 0.003,
      diameterRatio: 2.2,
      overAndUnderCenterOpacity: 1,
      onSelectedItemChanged: (index) => onChanged(index % count),
      childDelegate: delegate,
    );
  }
}
