import 'package:flutter/material.dart';

import '../../data/elderly_help_request_controller.dart';
import '../../../help_requests/domain/help_request.dart';

class ElderlyHelpRequestCard extends StatelessWidget {
  const ElderlyHelpRequestCard({
    super.key,
    required this.state,
    required this.activeRequest,
    required this.errorMessage,
    required this.onRequestHelp,
    required this.onRetry,
  });

  final ElderlyHelpRequestState state;
  final HelpRequestRecord? activeRequest;
  final String? errorMessage;
  final VoidCallback? onRequestHelp;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ElderlyHelpRequestState.initialLoading => const Card(
        key: Key('elderly-help-loading'),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Checking help-request status…',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
      ElderlyHelpRequestState.available => Semantics(
        label: 'Request help from your caregiver',
        button: true,
        child: SizedBox(
          width: double.infinity,
          height: 64,
          child: FilledButton(
            key: const Key('elderly-request-help'),
            onPressed: onRequestHelp,
            child: const Text(
              'Request Help',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
      ElderlyHelpRequestState.sending => SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton.icon(
          key: Key('elderly-help-sending'),
          onPressed: null,
          icon: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          label: Text('Sending request…'),
        ),
      ),
      ElderlyHelpRequestState.active => Card(
        key: const Key('elderly-help-active'),
        child: ListTile(
          leading: const Icon(Icons.check_circle_rounded),
          title: Text(_activeTitle),
          subtitle: Text(_activeMessage),
        ),
      ),
      ElderlyHelpRequestState.error => Card(
        key: const Key('elderly-help-error'),
        child: ListTile(
          leading: const Icon(Icons.cloud_off_rounded),
          title: const Text('Unable to update help status'),
          subtitle: Text(
            errorMessage ?? 'Something went wrong. Please try again.',
          ),
          trailing: TextButton(
            key: const Key('elderly-help-retry'),
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ),
      ),
    };
  }

  String get _activeTitle {
    return switch (activeRequest?.status) {
      HelpRequestStatus.acknowledged =>
        'Your caregiver acknowledged your request',
      HelpRequestStatus.resolved => 'Your help request was resolved',
      _ => 'Help request sent',
    };
  }

  String get _activeMessage {
    return switch (activeRequest?.status) {
      HelpRequestStatus.acknowledged =>
        'Your caregiver knows that you need assistance.',
      HelpRequestStatus.resolved =>
        'Your caregiver marked this request as resolved.',
      _ => 'Your caregiver will be notified.',
    };
  }
}
