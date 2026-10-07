import 'package:flutter/material.dart';

import '../../../../models/sleep_data.dart';
import '../../../../interfaces/pages/records/sleep_history_page.dart';
import 'elderly_widgets.dart';

class SleepDisplay extends StatelessWidget {
  final SleepData sleepData;

  const SleepDisplay({super.key, required this.sleepData});

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final List<SleepSessionData> todaySessions = sleepData.sessions.where((
      session,
    ) {
      final DateTime start = DateTime.parse(session.startTime).toLocal();
      return start.year == now.year &&
          start.month == now.month &&
          start.day == now.day;
    }).toList();

    String value = '--';
    String caption = 'No sleep data today';

    if (todaySessions.isNotEmpty) {
      final SleepSessionData session = todaySessions.first;
      final DateTime start = DateTime.parse(session.startTime).toLocal();
      final DateTime end = DateTime.parse(session.endTime).toLocal();
      final Duration duration = end.difference(start);
      final int hours = duration.inHours;
      final int minutes = duration.inMinutes.remainder(60);
      value = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
      caption = '${_formatTime(start)} – ${_formatTime(end)}';
    }

    return ElderlyVitalTile(
      backgroundAsset: ElderlyVitalTile.sleepBackground,
      iconAsset: ElderlyVitalTile.sleepIcon,
      title: 'Sleep',
      value: value,
      caption: caption,
      textColor: ElderlyVitalTile.sleepColor,
      onTap: () => Navigator.push(
        context,
        elderlyRoute<void>(
          context,
          (_) => SleepHistoryPage(sleepData: sleepData),
        ),
      ),
    );
  }

  static String _formatTime(DateTime dateTime) {
    final int hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour == 0
        ? 12
        : dateTime.hour;
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    final String period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
