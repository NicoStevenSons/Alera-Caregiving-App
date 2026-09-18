import 'package:flutter/material.dart';

import '../../../models/steps_data.dart';

class StepsHistoryPage extends StatelessWidget {
  final StepsData stepsData;

  const StepsHistoryPage({super.key, required this.stepsData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        title: const Text('Step Records'),
      ),

      body: stepsData.sessions.isEmpty
          ? const Center(child: Text('No step records available'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // SUMMARY CARD
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.directions_walk,
                          size: 40,
                          color: Colors.blue,
                        ),

                        const SizedBox(width: 16),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Steps',
                              style: TextStyle(fontSize: 16),
                            ),

                            Text(
                              '${stepsData.totalSteps}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Text('${stepsData.sessions.length} sessions'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Step Sessions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                ...stepsData.sessions.map((StepSessionData session) {
                  final DateTime? start = DateTime.tryParse(
                    session.startTime,
                  )?.toLocal();

                  final DateTime? end = DateTime.tryParse(
                    session.endTime,
                  )?.toLocal();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.directions_walk),
                      ),

                      title: Text(
                        '${session.stepCount} steps',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      subtitle: Text(
                        '${_formatTime(start)} - '
                        '${_formatTime(end)}',
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }

  static String _formatTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '--';
    }

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
