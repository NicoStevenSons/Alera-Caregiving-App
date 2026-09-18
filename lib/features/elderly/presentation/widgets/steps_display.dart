import 'package:flutter/material.dart';

import '../../../../models/steps_data.dart';
import '../../../../interfaces/pages/records/steps_history_page.dart';

class StepsDisplay extends StatelessWidget {
  final StepsData stepsData;

  const StepsDisplay({super.key, required this.stepsData});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,

        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StepsHistoryPage(stepsData: stepsData),
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
                    Icon(Icons.stairs, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Activity'),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 70),
                  child: Row(
                    children: [
                      Text('${stepsData.sessions.length} sessions today'),
                    ],
                  ),
                ),

                Row(
                  children: [
                    Text(
                      '${stepsData.displayedTotalSteps} Steps',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
