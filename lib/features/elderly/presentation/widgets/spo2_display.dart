import 'package:flutter/material.dart';

import '../../../../models/spo2_data.dart';
import '../../../../Services/upload_queue_service.dart';
import '../../../../interfaces/pages/records/spo2_history_page.dart';

class SpO2Display extends StatelessWidget {
  final SpO2Data spo2Data;
  final UploadQueueService uploadQueueService;

  const SpO2Display({
    super.key,
    required this.spo2Data,
    required this.uploadQueueService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SpO2HistoryPage(uploadQueueService: uploadQueueService),
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
                  Icon(Icons.bloodtype, color: Colors.red),
                  SizedBox(width: 8),
                  Text('SpO2'),
                ],
              ),

              const SizedBox(height: 70),

              Text(
                '${spo2Data.displayedPercent}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
