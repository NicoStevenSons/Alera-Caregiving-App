import 'package:flutter/material.dart';

import '../../../../models/steps_data.dart';
import '../../../../interfaces/pages/records/steps_history_page.dart';
import 'elderly_widgets.dart';

class StepsDisplay extends StatelessWidget {
  final StepsData stepsData;

  const StepsDisplay({super.key, required this.stepsData});

  @override
  Widget build(BuildContext context) {
    final String steps = stepsData.displayedTotalSteps;
    final int sessions = stepsData.sessions.length;

    return ElderlyVitalTile(
      backgroundAsset: ElderlyVitalTile.activityBackground,
      iconAsset: ElderlyVitalTile.activityIcon,
      title: 'Activity',
      value: steps,
      unit: steps == '--' ? '' : 'steps',
      caption: sessions == 1 ? '1 session today' : '$sessions sessions today',
      textColor: ElderlyVitalTile.activityColor,
      onTap: () => Navigator.push(
        context,
        elderlyRoute<void>(
          context,
          (_) => StepsHistoryPage(stepsData: stepsData),
        ),
      ),
    );
  }
}
