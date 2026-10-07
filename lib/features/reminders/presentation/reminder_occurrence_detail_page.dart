import 'package:flutter/material.dart';

import '../../../design_system/alera_colors.dart';
import '../../../design_system/alera_typography.dart';
import '../../../design_system/widgets/alera_card.dart';
import '../../../design_system/widgets/alera_svg_icon.dart';
import '../data/reminder_api_data_source.dart';
import '../data/reminder_controller.dart';
import '../data/reminder_timeline_controller.dart';
import '../domain/reminder_models.dart';
import 'reminder_formatters.dart';
import 'widgets/reminder_history_section.dart';
import 'widgets/reminder_timeline.dart' show reminderIsActionable;

typedef ReminderOccurrenceAction =
    Future<void> Function(ReminderOccurrence occurrence);

/// Caregiver view of one reminder occurrence: what it is, where it stands,
/// the usual caregiver actions and the full history ("Timeline").
class ReminderOccurrenceDetailPage extends StatefulWidget {
  const ReminderOccurrenceDetailPage({
    super.key,
    required this.occurrence,
    required this.controller,
    required this.eventsDataSource,
    required this.onComplete,
    required this.onSnooze,
    required this.onCancel,
  });

  /// Snapshot used until [controller] reports a fresher copy.
  final ReminderOccurrence occurrence;
  final ReminderController controller;
  final ReminderEventsDataSource eventsDataSource;
  final ReminderOccurrenceAction onComplete;
  final ReminderOccurrenceAction onSnooze;
  final ReminderOccurrenceAction onCancel;

  @override
  State<ReminderOccurrenceDetailPage> createState() =>
      _ReminderOccurrenceDetailPageState();
}

class _ReminderOccurrenceDetailPageState
    extends State<ReminderOccurrenceDetailPage> {
  late final ReminderTimelineController _timeline;

  @override
  void initState() {
    super.initState();
    _timeline = ReminderTimelineController(
      dataSource: widget.eventsDataSource,
      occurrenceId: widget.occurrence.id,
    )..load();
  }

  @override
  void dispose() {
    _timeline.dispose();
    super.dispose();
  }

  ReminderOccurrence get _current {
    for (final item in widget.controller.occurrences) {
      if (item.id == widget.occurrence.id) return item;
    }
    return widget.occurrence;
  }

  Future<void> _run(ReminderOccurrenceAction action) async {
    await action(_current);
    if (mounted) await _timeline.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AleraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AleraColors.primarySoft,
        titleSpacing: 0,
        title: const Text('Reminder', style: AleraTypography.pageTitle),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) => _content(context, _current),
      ),
    );
  }

  Widget _content(BuildContext context, ReminderOccurrence occurrence) {
    final actionable = reminderIsActionable(occurrence.status);
    return ListView(
      key: const Key('reminder-detail'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        AleraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AleraSvgIcon(
                    assetPath: reminderCategoryAsset(occurrence.category),
                    width: 32,
                    height: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      occurrence.title,
                      key: const Key('reminder-detail-title'),
                      style: AleraTypography.sectionTitle.copyWith(
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _Fact(
                label: 'Category',
                value: reminderTitleCase(occurrence.category.apiValue),
              ),
              _Fact(
                key: const Key('reminder-detail-status'),
                label: 'Status',
                value: reminderTitleCase(occurrence.status.apiValue),
              ),
              _Fact(
                label: 'Scheduled',
                value: _when(occurrence.scheduledAt),
              ),
              _Fact(label: 'Due', value: _when(occurrence.dueAt)),
              if (occurrence.instructions case final text?)
                _Fact(
                  key: const Key('reminder-detail-instructions'),
                  label: 'Instructions',
                  value: text,
                ),
            ],
          ),
        ),
        if (actionable) ...[
          const SizedBox(height: 12),
          AleraCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ReminderActionRow(
                  key: const Key('reminder-action-complete'),
                  icon: Icons.check_circle,
                  label: 'Mark complete',
                  onTap: () => _run(widget.onComplete),
                ),
                if (occurrence.snoozeAllowed) ...[
                  const ReminderActionDivider(),
                  ReminderActionRow(
                    key: const Key('reminder-action-snooze'),
                    icon: Icons.snooze,
                    label: 'Snooze ${occurrence.defaultSnoozeMinutes} minutes',
                    onTap: () => _run(widget.onSnooze),
                  ),
                ],
                const ReminderActionDivider(),
                ReminderActionRow(
                  key: const Key('reminder-action-cancel'),
                  icon: Icons.event_busy,
                  label: 'Cancel this reminder',
                  destructive: true,
                  onTap: () => _run(widget.onCancel),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        ReminderHistorySection(controller: _timeline),
      ],
    );
  }

  static String _when(DateTime value) =>
      '${reminderShortDate(value.toLocal())} · ${reminderClock(value)}';
}

class _Fact extends StatelessWidget {
  const _Fact({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: AleraTypography.body.copyWith(
              color: AleraColors.textSecondary,
            ),
          ),
        ),
        Expanded(child: Text(value, style: AleraTypography.body)),
      ],
    ),
  );
}

class ReminderActionRow extends StatelessWidget {
  const ReminderActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AleraColors.critical : AleraColors.selected;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: destructive
                      ? AleraColors.critical
                      : AleraColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReminderActionDivider extends StatelessWidget {
  const ReminderActionDivider();

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    thickness: 1,
    indent: 16,
    endIndent: 16,
    color: AleraColors.divider,
  );
}
