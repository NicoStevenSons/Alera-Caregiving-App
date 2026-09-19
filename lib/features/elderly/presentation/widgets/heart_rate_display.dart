import 'package:flutter/material.dart';

import '../../../../models/heart_rate_data.dart';
import '../../../../Services/upload_queue_service.dart';
import '../../../../interfaces/pages/records/heart_rate_history_page.dart';

class HeartRateDisplay extends StatelessWidget {
  final HeartRateData heartRateData;
  final UploadQueueService uploadQueueService;

  const HeartRateDisplay({
    super.key,
    required this.heartRateData,
    required this.uploadQueueService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  HeartRateHistoryPage(uploadQueueService: uploadQueueService),
            ),
          );
        },

        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text('Heart Rate'),
                ],
              ),

              Padding(
                padding: const EdgeInsets.only(top: 70),
                child: Row(
                  children: [
                    Text(
                      '${heartRateData.displayedHeartRate} BPM',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
