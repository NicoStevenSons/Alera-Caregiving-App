import 'package:flutter/material.dart';

import '../../../../design_system/alera_spacing.dart';
import '../../../help_requests/domain/help_request.dart';
import '../../data/api/caregiver_help_request_api_data_source.dart';
import '../../data/help_requests/caregiver_help_request_detail_controller.dart';
import '../../data/help_requests/caregiver_help_request_note.dart';
import '../widgets/caregiver_page_app_bar.dart';
import '../../../../design_system/widgets/alera_snackbar.dart';
import '../../../../design_system/widgets/alera_loader.dart';
import '../../../../design_system/widgets/alera_pill.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/alera_colors.dart';

class CaregiverHelpRequestDetailPage extends StatefulWidget {
  const CaregiverHelpRequestDetailPage({
    super.key,
    required this.helpRequestId,
    required this.dataSource,
    required this.notesDataSource,
  });

  final String helpRequestId;
  final CaregiverHelpRequestDataSource dataSource;
  final CaregiverHelpRequestNotesDataSource notesDataSource;

  @override
  State<CaregiverHelpRequestDetailPage> createState() =>
      _CaregiverHelpRequestDetailPageState();
}

class _CaregiverHelpRequestDetailPageState
    extends State<CaregiverHelpRequestDetailPage> {
  late final CaregiverHelpRequestDetailController _controller;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = CaregiverHelpRequestDetailController(
      helpRequestId: widget.helpRequestId,
      dataSource: widget.dataSource,
      notesDataSource: widget.notesDataSource,
    );
    _controller.load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitNote() async {
    FocusScope.of(context).unfocus();
    final added = await _controller.addNote(_noteController.text);

    if (!mounted) return;

    if (added) {
      _noteController.clear();
      showAleraSnackBar(
        context,
        'Caregiver note added.',
        type: AleraSnackBarType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CaregiverPageAppBar(title: 'Help request'),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return switch (_controller.state) {
            HelpRequestDetailState.initialLoading => const Center(
              child: AleraLoader.large(),
            ),
            HelpRequestDetailState.error => _DetailError(
              message:
                  _controller.errorMessage ??
                  'Unable to load this help request.',
              onRetry: _controller.load,
            ),
            HelpRequestDetailState.success => _buildDetail(
              _controller.request!,
            ),
          };
        },
      ),
    );
  }

  Widget _buildDetail(HelpRequestRecord request) {
    return RefreshIndicator(
      onRefresh: _controller.load,
      child: ListView(
        key: const Key('help-request-detail'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AleraSpacing.large),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AleraSpacing.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.patientDisplayName ?? 'Patient',
                    style: AleraTypography.heading,
                  ),
                  const SizedBox(height: AleraSpacing.small),
                  AleraPill(
                    label: _statusLabel(request.status),
                    variant: AleraPillVariant.label,
                  ),
                  if (request.message != null) ...[
                    const SizedBox(height: AleraSpacing.medium),
                    Text(
                      request.message!,
                      style: AleraTypography.body.copyWith(
                        color: AleraColors.textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AleraSpacing.large),
          Text('Lifecycle', style: AleraTypography.sectionTitle),
          const SizedBox(height: AleraSpacing.small),
          Card(
            child: Column(
              children: [
                _LifecycleTile(
                  icon: Icons.notifications_active,
                  title: 'Requested',
                  time: request.requestedAt,
                ),
                if (request.acknowledgedAt != null)
                  _LifecycleTile(
                    icon: Icons.visibility,
                    title: 'Acknowledged',
                    time: request.acknowledgedAt!,
                  ),
                if (request.resolvedAt != null)
                  _LifecycleTile(
                    icon: Icons.check_circle,
                    title: 'Resolved',
                    time: request.resolvedAt!,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AleraSpacing.large),
          Text(
            'Caregiver notes',
            style: AleraTypography.sectionTitle,
          ),
          const SizedBox(height: AleraSpacing.small),
          Text(
            'Private to assigned caregivers.',
            style: AleraTypography.bodySmall,
          ),
          const SizedBox(height: AleraSpacing.small),
          if (_controller.notes.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(AleraSpacing.large),
                child: Text('No caregiver notes yet.'),
              ),
            )
          else
            ..._controller.notes.map(_buildNote),
          const SizedBox(height: AleraSpacing.medium),
          TextField(
            key: const Key('help-request-note-input'),
            controller: _noteController,
            enabled: !_controller.addingNote,
            minLines: 2,
            maxLines: 5,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Add caregiver note',
              hintText: 'Example: Called patient; family is on the way.',
              errorText: _controller.noteErrorMessage,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AleraSpacing.small),
          FilledButton.icon(
            key: const Key('add-help-request-note'),
            onPressed: _controller.addingNote ? null : _submitNote,
            icon: _controller.addingNote
                ? const AleraLoader.small()
                : const Icon(Icons.note_add),
            label: Text(_controller.addingNote ? 'Adding…' : 'Add note'),
          ),
          if (_controller.canRetryNote) ...[
            const SizedBox(height: AleraSpacing.small),
            OutlinedButton.icon(
              key: const Key('retry-help-request-note'),
              onPressed: _controller.retryNote,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry last note'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNote(HelpRequestNoteRecord note) {
    return Card(
      key: ValueKey<String>('help-request-note-${note.id}'),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(note.note),
        subtitle: Text(
          '${note.authorDisplayName ?? 'Caregiver'} • '
          '${_formatDateTime(note.createdAt)}',
        ),
      ),
    );
  }
}

class _LifecycleTile extends StatelessWidget {
  const _LifecycleTile({
    required this.icon,
    required this.title,
    required this.time,
  });

  final IconData icon;
  final String title;
  final DateTime time;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(_formatDateTime(time)),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AleraSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: AleraSpacing.medium),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AleraSpacing.medium),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
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

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';

  return '${local.month}/${local.day}/${local.year} '
      '$hour:$minute $period';
}
