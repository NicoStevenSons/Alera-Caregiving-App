import 'package:flutter/material.dart';

import '../../../Services/upload_queue_service.dart';
import '../../../models/heart_rate_data.dart';
import '../../../models/sleep_data.dart';
import '../../../models/spo2_data.dart';
import '../../../models/steps_data.dart';
import 'widgets/heart_rate_display.dart';
import 'widgets/sleep_display.dart';
import 'widgets/spo2_display.dart';
import 'widgets/steps_display.dart';

class ElderlyHomePage extends StatelessWidget {
  const ElderlyHomePage({
    super.key,
    required this.heartRateData,
    required this.spo2Data,
    required this.stepsData,
    required this.sleepData,
    required this.uploadQueueService,
    this.onRequestHelp,
  });

  final HeartRateData heartRateData;
  final SpO2Data spo2Data;
  final StepsData stepsData;
  final SleepData sleepData;
  final UploadQueueService uploadQueueService;

  /// Remains disabled until the help-request backend flow is implemented.
  final VoidCallback? onRequestHelp;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey<String>('elderly-home'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Semantics(
          label: 'Request help from your caregiver',
          button: true,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              key: const Key('elderly-request-help'),
              onPressed: onRequestHelp,
              icon: const Icon(Icons.sos_rounded),
              label: const Text('Request Help'),
            ),
          ),
        ),
        if (onRequestHelp == null) ...[
          const SizedBox(height: 8),
          Text(
            'Help requests will be available soon.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: HeartRateDisplay(
                heartRateData: heartRateData,
                uploadQueueService: uploadQueueService,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SpO2Display(
                spo2Data: spo2Data,
                uploadQueueService: uploadQueueService,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StepsDisplay(stepsData: stepsData),
        const SizedBox(height: 16),
        SleepDisplay(sleepData: sleepData),
      ],
    );
  }
}
