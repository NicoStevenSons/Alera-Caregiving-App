import 'package:flutter/material.dart';

import '../../../../Services/upload_queue_service.dart';

class ClearPendingQueueButton extends StatelessWidget {
  final UploadQueueService uploadQueueService;
  final String? metricType;

  const ClearPendingQueueButton({
    super.key,
    required this.uploadQueueService,
    this.metricType,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Clear Pending Queue?'),
              content: const Text(
                'This will permanently delete all '
                'health readings currently waiting '
                'to be uploaded.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Clear'),
                ),
              ],
            );
          },
        );

        if (confirmed != true) {
          return;
        }

        final int deletedCount;

        if (metricType != null) {
          deletedCount = await uploadQueueService.clearPendingQueueByMetric(
            metricType!,
          );
        } else {
          deletedCount = await uploadQueueService.clearPendingQueue();
        }

        debugPrint(
          'Cleared $deletedCount pending '
          'queue items.',
        );

        if (!context.mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cleared $deletedCount '
              'pending readings.',
            ),
          ),
        );
      },
      child: const Text('Clear Pending Queue'),
    );
  }
}
