import 'package:flutter/material.dart';

import '../../../../Services/upload_queue_service.dart';
import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/widgets/alera_confirmation_dialog.dart';

class ClearPendingQueueButton extends StatelessWidget {
  final UploadQueueService uploadQueueService;
  final String? metricType;
  final VoidCallback? onCleared;

  const ClearPendingQueueButton({
    super.key,
    required this.uploadQueueService,
    this.metricType,
    this.onCleared,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () async {
        final bool? confirmed = await showAleraConfirmationDialog(
          context,
          large: true,
          icon: Icons.delete,
          title: 'Clear unsent readings?',
          message:
              'This will permanently delete the health readings that are '
              'still waiting to be sent to your caregiver.',
          cancelLabel: 'Cancel',
          confirmLabel: 'Clear',
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

        onCleared?.call();

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
      icon: const Icon(Icons.delete),
      label: const Text('Clear unsent readings'),
      style: TextButton.styleFrom(
        foregroundColor: AleraColors.textSecondary,
      ),
    );
  }
}
