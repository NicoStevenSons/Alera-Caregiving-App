import 'package:flutter/material.dart';

import '../../../../design_system/alera_spacing.dart';
import '../../../help_requests/domain/help_request.dart';
import '../../data/api/caregiver_help_request_api_data_source.dart';
import '../../data/help_requests/caregiver_help_request_history_controller.dart';
import '../widgets/caregiver_page_app_bar.dart';
import 'caregiver_help_request_detail_page.dart';

class CaregiverHelpRequestHistoryPage extends StatefulWidget {
  const CaregiverHelpRequestHistoryPage({
    super.key,
    required this.dataSource,
    required this.notesDataSource,
  });

  final CaregiverHelpRequestDataSource dataSource;
  final CaregiverHelpRequestNotesDataSource notesDataSource;

  @override
  State<CaregiverHelpRequestHistoryPage> createState() =>
      _CaregiverHelpRequestHistoryPageState();
}

class _CaregiverHelpRequestHistoryPageState
    extends State<CaregiverHelpRequestHistoryPage> {
  late final CaregiverHelpRequestHistoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CaregiverHelpRequestHistoryController(
      dataSource: widget.dataSource,
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openRequest(HelpRequestRecord request) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CaregiverHelpRequestDetailPage(
          helpRequestId: request.id,
          dataSource: widget.dataSource,
          notesDataSource: widget.notesDataSource,
        ),
      ),
    );

    if (mounted) await _controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CaregiverPageAppBar(title: 'Help request history'),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AleraSpacing.large,
                  AleraSpacing.medium,
                  AleraSpacing.large,
                  AleraSpacing.small,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        key: const Key('help-history-active-filter'),
                        label: const Text('Active'),
                        selected:
                            _controller.filter ==
                            HelpRequestHistoryFilter.active,
                        onSelected: (_) => _controller.selectFilter(
                          HelpRequestHistoryFilter.active,
                        ),
                      ),
                    ),
                    const SizedBox(width: AleraSpacing.small),
                    Expanded(
                      child: ChoiceChip(
                        key: const Key('help-history-resolved-filter'),
                        label: const Text('Resolved'),
                        selected:
                            _controller.filter ==
                            HelpRequestHistoryFilter.resolved,
                        onSelected: (_) => _controller.selectFilter(
                          HelpRequestHistoryFilter.resolved,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildContent()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return switch (_controller.state) {
      HelpRequestHistoryState.initialLoading => const Center(
        child: CircularProgressIndicator(),
      ),
      HelpRequestHistoryState.error => _HistoryMessage(
        icon: Icons.cloud_off_outlined,
        message:
            _controller.errorMessage ?? 'Unable to load help-request history.',
        actionLabel: 'Retry',
        onAction: _controller.load,
      ),
      HelpRequestHistoryState.success when _controller.requests.isEmpty =>
        _HistoryMessage(
          icon: _controller.filter == HelpRequestHistoryFilter.active
              ? Icons.check_circle_outline
              : Icons.history,
          message: _controller.filter == HelpRequestHistoryFilter.active
              ? 'No active help requests.'
              : 'No resolved help requests yet.',
        ),
      HelpRequestHistoryState.success => RefreshIndicator(
        onRefresh: _controller.load,
        child: ListView.separated(
          key: const Key('help-request-history-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AleraSpacing.large),
          itemCount: _controller.requests.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AleraSpacing.small),
          itemBuilder: (context, index) {
            final request = _controller.requests[index];

            return Card(
              child: ListTile(
                key: ValueKey<String>('help-history-request-${request.id}'),
                leading: CircleAvatar(child: Icon(_statusIcon(request.status))),
                title: Text(request.patientDisplayName ?? 'Patient'),
                subtitle: Text(
                  [
                    _statusLabel(request.status),
                    _formatDateTime(request.requestedAt),
                    if (request.message != null) request.message!,
                  ].join(' • '),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openRequest(request),
              ),
            );
          },
        ),
      ),
    };
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AleraSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: AleraSpacing.medium),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AleraSpacing.medium),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

String _statusLabel(HelpRequestStatus status) => switch (status) {
  HelpRequestStatus.pending => 'Pending',
  HelpRequestStatus.acknowledged => 'Acknowledged',
  HelpRequestStatus.resolved => 'Resolved',
};

IconData _statusIcon(HelpRequestStatus status) => switch (status) {
  HelpRequestStatus.pending => Icons.notifications_active_outlined,
  HelpRequestStatus.acknowledged => Icons.visibility_outlined,
  HelpRequestStatus.resolved => Icons.check_circle_outline,
};

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';

  return '${local.month}/${local.day}/${local.year} '
      '$hour:$minute $period';
}
