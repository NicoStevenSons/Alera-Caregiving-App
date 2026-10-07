import 'package:flutter/material.dart';

import '../../../design_system/widgets/alera_back_button.dart';

import '../../../features/elderly/presentation/widgets/elderly_widgets.dart';
import '../../../models/steps_data.dart';

class StepsHistoryPage extends StatelessWidget {
  final StepsData stepsData;

  const StepsHistoryPage({super.key, required this.stepsData});

  @override
  Widget build(BuildContext context) {
    final int sessions = stepsData.sessions.length;

    return Scaffold(
      appBar: AppBar(
        leading: const AleraBackButton(size: 32),
        title: const Text('Activity'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          ElderlyVitalTile(
            height: 180,
            backgroundAsset: ElderlyVitalTile.activityBackground,
            iconAsset: ElderlyVitalTile.activityIcon,
            title: 'Steps today',
            value: stepsData.displayedTotalSteps,
            unit: sessions == 0 ? '' : 'steps',
            caption: sessions == 1 ? '1 session' : '$sessions sessions',
            textColor: ElderlyVitalTile.activityColor,
          ),
          const SizedBox(height: 24),
          const ElderlySectionTitle('Walking sessions'),
          const SizedBox(height: 12),
          if (sessions == 0)
            const ElderlyStateMessage(
              icon: Icons.directions_walk,
              title: 'No steps recorded yet',
              message: 'Your walking sessions will appear here.',
            )
          else
            for (final StepSessionData session in stepsData.sessions)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElderlyReadingRow(
                  icon: Icons.directions_walk,
                  color: ElderlyVitalTile.activityColor,
                  value: '${session.stepCount} steps',
                  caption: _range(session),
                ),
              ),
        ],
      ),
    );
  }

  static String _range(StepSessionData session) {
    final DateTime? start = DateTime.tryParse(session.startTime);
    final DateTime? end = DateTime.tryParse(session.endTime);
    if (start == null || end == null) return '--';
    return '${elderlyTime(start)} – ${elderlyTime(end)}';
  }
}
