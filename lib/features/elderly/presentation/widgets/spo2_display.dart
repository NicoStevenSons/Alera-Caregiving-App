import 'package:flutter/material.dart';

import '../../../../models/spo2_data.dart';
import '../../../../Services/upload_queue_service.dart';
import '../../../../interfaces/pages/records/spo2_history_page.dart';
import 'elderly_widgets.dart';

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

    return ElderlyVitalTile(
      backgroundAsset: ElderlyVitalTile.spo2Background,
      iconAsset: ElderlyVitalTile.spo2Icon,
      title: 'SpO₂',
      value: hasReading ? '${spo2Data.percent!.round()}' : '--',
      unit: '%',
      caption: hasReading ? spo2Data.displayedStatus : 'Waiting for watch',
      textColor: ElderlyVitalTile.spo2Color,
      onTap: () => Navigator.push(
        context,
        elderlyRoute<void>(
          context,
          (_) => SpO2HistoryPage(uploadQueueService: uploadQueueService),
        ),
      ),
    );
  }
}
