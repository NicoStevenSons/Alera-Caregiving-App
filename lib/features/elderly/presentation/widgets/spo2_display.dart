import 'package:flutter/material.dart';

import '../../../../models/spo2_data.dart';
import '../../../../Services/upload_queue_service.dart';
import '../../../../interfaces/pages/records/spo2_history_page.dart';

class SpO2Display extends StatelessWidget {
  const SpO2Display({
    super.key,
    required this.spo2Data,
    required this.uploadQueueService,
  });

  final SpO2Data spo2Data;
  final UploadQueueService uploadQueueService;

  @override
  Widget build(BuildContext context) {
    final hasReading = spo2Data.percent != null && spo2Data.percent! > 0;
    final value = hasReading ? '${spo2Data.percent!.round()}%' : '-- %';

    return SizedBox(
      height: 154,
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
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
                    Icon(Icons.bloodtype_rounded, color: Color(0xFF7161D7), size: 28),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SpO₂',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasReading ? spo2Data.displayedStatus : 'Waiting for watch',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
