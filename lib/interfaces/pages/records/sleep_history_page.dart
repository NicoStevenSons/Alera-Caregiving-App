import 'package:flutter/material.dart';

import '../../../features/elderly/presentation/widgets/elderly_widgets.dart';
import '../../../models/sleep_data.dart';

class SleepHistoryPage extends StatelessWidget {
  final SleepData sleepData;

  const SleepHistoryPage({super.key, required this.sleepData});

  @override
  Widget build(BuildContext context) {
    final List<SleepSessionData> sessions = sleepData.sessions;
    final SleepSessionData? latest = sessions.isEmpty ? null : sessions.first;

    return Scaffold(
      appBar: AppBar(title: const Text('Sleep')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          ElderlyVitalTile(
            height: 180,
            backgroundAsset: ElderlyVitalTile.sleepBackground,
            iconAsset: ElderlyVitalTile.sleepIcon,
            title: 'Latest sleep',
            value: latest == null ? '--' : _duration(latest),
            caption: latest == null
                ? 'No sleep recorded yet'
                : elderlyFriendlyDateTime(DateTime.tryParse(latest.startTime)),
            textColor: ElderlyVitalTile.sleepColor,
          ),
          const SizedBox(height: 24),
          const ElderlySectionTitle('Sleep history'),
          const SizedBox(height: 12),
          if (sessions.isEmpty)
            const ElderlyStateMessage(
              icon: Icons.bedtime,
              title: 'No sleep history yet',
              message: 'Your nights of sleep will appear here.',
            )
          else
            for (final SleepSessionData session in sessions)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElderlyReadingRow(
                  icon: Icons.bedtime,
                  color: ElderlyVitalTile.sleepColor,
                  value: _duration(session),
                  caption: _range(session),
                ),
              ),
        ],
      ),
    );
  }

  static String _duration(SleepSessionData session) {
    final DateTime? start = DateTime.tryParse(session.startTime);
    final DateTime? end = DateTime.tryParse(session.endTime);
    if (start == null || end == null) return '--';
    final Duration d = end.difference(start);
    final int hours = d.inHours;
    final int minutes = d.inMinutes.remainder(60);
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  static String _range(SleepSessionData session) {
    final DateTime? start = DateTime.tryParse(session.startTime);
    final DateTime? end = DateTime.tryParse(session.endTime);
    if (start == null || end == null) return '--';
    return '${elderlyFriendlyDateTime(start)} – ${elderlyTime(end)}';
  }
}
