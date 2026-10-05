import 'package:flutter/material.dart';

import '../../../data/help_requests/caregiver_help_request_controller.dart';
import '../../../../help_requests/domain/help_request.dart';

class HomeHelpRequestsPreview extends StatelessWidget {
  const HomeHelpRequestsPreview({
    super.key,
    required this.controller,
    this.maxItems = 3,
  });

  final CaregiverHelpRequestController controller;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.state == CaregiverHelpRequestState.initialLoading) {
          return const Card(
            key: Key('home-help-requests-loading'),
            child: ListTile(
              leading: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              title: Text('Checking help requests…'),
            ),
          );
        }

        if (controller.state == CaregiverHelpRequestState.error &&
            controller.requests.isEmpty) {
          return Card(
            key: const Key('home-help-requests-error'),
            child: ListTile(
              leading: const Icon(Icons.cloud_off_rounded),
              title: const Text('Unable to load help requests'),
              subtitle: Text(controller.errorMessage ?? 'Please try again.'),
              trailing: TextButton(
                key: const Key('home-help-requests-retry'),
                onPressed: () {
                  controller.load();
                },
                child: const Text('Retry'),
              ),
            ),
          );
        }

        if (controller.requests.isEmpty) {
          return const SizedBox.shrink(key: Key('home-help-requests-empty'));
        }

        final visible = controller.requests
            .take(maxItems)
            .toList(growable: false);

        return Card(
          key: const Key('home-help-requests'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sos_rounded),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Help requests',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (controller.pendingCount > 0)
                      Badge(
                        key: const Key('home-help-requests-badge'),
                        label: Text('${controller.pendingCount}'),
                      ),
                  ],
                ),
                if (controller.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    controller.errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (controller.actionErrorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    controller.actionErrorMessage!,
                    key: const Key('home-help-request-action-error'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                for (var index = 0; index < visible.length; index++) ...[
                  _HelpRequestTile(
                    request: visible[index],
                    busy: controller.isBusy(visible[index].id),
                    onAcknowledge: () {
                      controller.acknowledge(visible[index].id);
                    },
                    onResolve: () {
                      controller.resolve(visible[index].id);
                    },
                  ),
                  if (index != visible.length - 1) const Divider(),
                ],
                if (controller.requests.length > visible.length) ...[
                  const Divider(),
                  Text(
                    '${controller.requests.length - visible.length} '
                    'more active help requests',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HelpRequestTile extends StatelessWidget {
  const _HelpRequestTile({
    required this.request,
    required this.busy,
    required this.onAcknowledge,
    required this.onResolve,
  });

  final HelpRequestRecord request;
  final bool busy;
  final VoidCallback onAcknowledge;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    final pending = request.status == HelpRequestStatus.pending;

    return Padding(
      key: ValueKey<String>('home-help-request-${request.id}'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.patientDisplayName ?? 'Patient',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(request.message ?? 'Requested assistance'),
          const SizedBox(height: 2),
          Text(
            '${pending ? 'Waiting for response' : 'Acknowledged'}'
            ' · ${_time(request.requestedAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (busy)
            const LinearProgressIndicator(key: Key('home-help-request-busy'))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (pending)
                  FilledButton.tonal(
                    key: ValueKey<String>('acknowledge-help-${request.id}'),
                    onPressed: onAcknowledge,
                    child: const Text('Acknowledge'),
                  ),
                OutlinedButton(
                  key: ValueKey<String>('resolve-help-${request.id}'),
                  onPressed: onResolve,
                  child: const Text('Resolve'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _time(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}
