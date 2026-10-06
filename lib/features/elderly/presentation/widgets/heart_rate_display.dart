import 'package:flutter/material.dart';

import '../../../../models/heart_rate_data.dart';
import '../../../../Services/upload_queue_service.dart';
import '../../../../interfaces/pages/records/heart_rate_history_page.dart';

class HeartRateDisplay extends StatelessWidget {
  const HeartRateDisplay({
    super.key,
    required this.heartRateData,
    required this.uploadQueueService,
  });

  final HeartRateData heartRateData;
  final UploadQueueService uploadQueueService;

  @override
  Widget build(BuildContext context) {
    final hasReading = heartRateData.bpm != null && heartRateData.bpm! > 0;
    final value = hasReading ? '${heartRateData.bpm} BPM' : '-- BPM';

    return SizedBox(
      height: 154,
      child: Card(
        elevation: 1,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => HeartRateHistoryPage(
                  uploadQueueService: uploadQueueService,
                ),
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
                    Icon(Icons.favorite_rounded, color: Color(0xFFFF6467)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Heart Rate',
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
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasReading
                      ? heartRateData.displayedStatus
                      : 'Waiting for watch',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
