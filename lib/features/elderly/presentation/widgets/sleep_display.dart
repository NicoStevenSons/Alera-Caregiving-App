import 'package:flutter/material.dart';

import '../../../../models/sleep_data.dart';
import '../../../../interfaces/pages/records/sleep_history_page.dart';

class SleepDisplay extends StatelessWidget {
  final SleepData sleepData;

  const SleepDisplay({super.key, required this.sleepData});

  @override
  Widget build(BuildContext context) {
    final List<SleepSessionData> todaySessions = sleepData.sessions.where((
      session,
    ) {
      final DateTime start = DateTime.parse(session.startTime).toLocal();

      final DateTime now = DateTime.now();

      return start.year == now.year &&
          start.month == now.month &&
          start.day == now.day;
    }).toList();

    if (todaySessions.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SleepHistoryPage(sleepData: sleepData),
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bedtime, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text('Sleep Today'),
                    ],
                  ),
                  SizedBox(height: 12),
                  Padding(
                    padding: EdgeInsets.only(top: 70),
                    child: Text(
                      'No sleep data available today',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final SleepSessionData session = todaySessions.first;

    final DateTime start = DateTime.parse(session.startTime).toLocal();

    final DateTime end = DateTime.parse(session.endTime).toLocal();

    final Duration duration = end.difference(start);

    final int hours = duration.inHours;

    final int minutes = duration.inMinutes.remainder(60);

    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SleepHistoryPage(sleepData: sleepData),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bedtime, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text(
                      'Sleep Today',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  '$hours hr $minutes min',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text('${todaySessions.length} sleep session(s) today'),

                const SizedBox(height: 8),

                Text('Start: ${_formatTime(start)}'),

                Text('End: ${_formatTime(end)}'),

                const SizedBox(height: 12),

                const Row(
                  children: [
                    Text(
                      'View Sleep History',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ],
            ),
          ),
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
