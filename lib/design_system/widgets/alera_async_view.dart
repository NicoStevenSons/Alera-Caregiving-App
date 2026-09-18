import 'package:flutter/material.dart';

import '../alera_colors.dart';
import '../alera_spacing.dart';
import '../alera_typography.dart';
import 'alera_button.dart';

class AleraLoadingView extends StatelessWidget {
  const AleraLoadingView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AleraSpacing.large),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (label != null) ...[
            const SizedBox(height: AleraSpacing.medium),
            Text(
              label!,
              style: AleraTypography.body,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    ),
  );
}

class AleraErrorView extends StatelessWidget {
  const AleraErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.icon = Icons.cloud_off_outlined,
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) => _AleraMessageView(
    icon: icon,
    title: 'Something went wrong',
    message: message,
    actionLabel: onRetry == null ? null : retryLabel,
    onAction: onRetry,
  );
}

class AleraEmptyView extends StatelessWidget {
  const AleraEmptyView({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => _AleraMessageView(
    icon: icon,
    title: title,
    message: message,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

class _AleraMessageView extends StatelessWidget {
  const _AleraMessageView({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AleraSpacing.large),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AleraColors.textSecondary),
          const SizedBox(height: AleraSpacing.small),
          Text(
            title,
            style: AleraTypography.sectionTitle.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: AleraSpacing.small),
            Text(
              message!,
              style: AleraTypography.body,
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AleraSpacing.medium),
            AleraButton(
              label: actionLabel!,
              onPressed: onAction,
              expand: false,
            ),
          ],
        ],
      ),
    ),
  );
}
