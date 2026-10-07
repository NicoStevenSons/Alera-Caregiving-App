import 'package:flutter/material.dart';

import '../../../../models/heart_rate_data.dart';
import '../../../../Services/upload_queue_service.dart';
import '../../../../interfaces/pages/records/heart_rate_history_page.dart';
import 'elderly_widgets.dart';

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

    return ElderlyVitalTile(
      backgroundAsset: ElderlyVitalTile.heartBackground,
      iconAsset: ElderlyVitalTile.heartIcon,
      title: 'Heart Rate',
      value: hasReading ? '${heartRateData.bpm}' : '--',
      unit: 'BPM',
      caption: hasReading ? heartRateData.displayedStatus : 'Waiting for watch',
      textColor: ElderlyVitalTile.heartColor,
      onTap: () => Navigator.push(
        context,
        elderlyRoute<void>(
          context,
          (_) => HeartRateHistoryPage(uploadQueueService: uploadQueueService),
        ),
      ),
    );
  }
}
