import 'package:flutter/material.dart';

import '../../../design_system/alera_colors.dart';
import '../../../design_system/alera_typography.dart';
import '../../../design_system/widgets/alera_card.dart';
import '../../../design_system/widgets/alera_chevron_app_bar.dart';
import '../../../design_system/widgets/alera_svg_icon.dart';
import '../data/reminder_api_data_source.dart';
import '../data/reminder_controller.dart';
import '../data/reminder_timeline_controller.dart';
import '../domain/reminder_models.dart';
import 'reminder_category_style.dart';
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
    this.patientName,
  });

  /// Snapshot used until [controller] reports a fresher copy.
  final ReminderOccurrence occurrence;
  final ReminderController controller;
  final ReminderEventsDataSource eventsDataSource;
  final ReminderOccurrenceAction onComplete;
  final ReminderOccurrenceAction onSnooze;
  final ReminderOccurrenceAction onCancel;

  /// Shown as `For <name>` under the title when known.
  final String? patientName;

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
      appBar: const AleraChevronAppBar(),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) => _content(context, _current),
      ),
    );
  }

  Widget _content(BuildContext context, ReminderOccurrence occurrence) {
    final actionable = reminderIsActionable(occurrence.status);
    final relative = _relative(occurrence, DateTime.now());
    return ListView(
      key: const Key('reminder-detail'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        AleraCard(
          color: reminderCategoryWash(occurrence.category, strength: 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: reminderCategoryTile(occurrence.category),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: AleraSvgIcon(
                      assetPath: reminderCategoryAsset(occurrence.category),
                      width: 34,
                      height: 34,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          occurrence.title,
                          key: const Key('reminder-detail-title'),
                          style: AleraTypography.sectionTitle.copyWith(
                            fontSize: 20,
                            height: 1.2,
                          ),
                        ),
                        if (widget.patientName case final name?)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'For $name',
                              key: const Key('reminder-detail-patient'),
                              style: AleraTypography.body.copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _StatusPill(
                    key: const Key('reminder-detail-status'),
                    status: occurrence.status,
                  ),
                  if (relative != null) ...[
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        relative,
                        key: const Key('reminder-detail-relative'),
                        style: AleraTypography.body.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AleraCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Details', style: AleraTypography.sectionTitle),
              const SizedBox(height: 10),
              _Fact(
                icon: Icons.schedule,
                label: 'Scheduled',
                value: _when(occurrence.scheduledAt),
              ),
              _Fact(
                icon: Icons.alarm,
                label: 'Due',
                value: _when(occurrence.dueAt),
              ),
              if (occurrence.missedAfterMinutes > 0)
                _Fact(
                  icon: Icons.event_busy,
                  label: 'Missed after',
                  value: '${occurrence.missedAfterMinutes} min',
                ),
              _Fact(
                icon: Icons.snooze,
                label: 'Snooze',
                value: occurrence.snoozeAllowed
                    ? '${occurrence.defaultSnoozeMinutes} min at a time'
                    : 'Not allowed',
              ),
              _Fact(
                icon: Icons.category,
                label: 'Category',
                value: reminderTitleCase(occurrence.category.apiValue),
              ),
              _Fact(
                icon: Icons.flag,
                label: 'Priority',
                value: reminderTitleCase(occurrence.priority.apiValue),
              ),
            ],
          ),
        ),
        if (occurrence.instructions case final text?) ...[
          const SizedBox(height: 12),
          AleraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Instructions', style: AleraTypography.sectionTitle),
                const SizedBox(height: 8),
                Text(
                  text,
                  key: const Key('reminder-detail-instructions'),
                  style: AleraTypography.body.copyWith(
                    color: AleraColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        const SizedBox(height: 12),
        ReminderHistorySection(controller: _timeline),
      ],
    );
  }

  static String _when(DateTime value) =>
      '${reminderShortDate(value.toLocal())} · ${reminderClock(value)}';

  /// "In 2 hr 10 min" / "3 hr ago" for reminders still in play or missed;
  /// null once the reminder is finished or canceled.
  static String? _relative(ReminderOccurrence occurrence, DateTime now) {
    switch (occurrence.status) {
      case ReminderOccurrenceStatus.completed:
      case ReminderOccurrenceStatus.completedLate:
      case ReminderOccurrenceStatus.canceled:
        return null;
      case ReminderOccurrenceStatus.upcoming:
      case ReminderOccurrenceStatus.due:
      case ReminderOccurrenceStatus.snoozed:
      case ReminderOccurrenceStatus.missed:
        final diff = occurrence.scheduledAt.difference(now);
        final span = _span(diff.abs());
        if (span == null) return 'Right now';
        return diff.isNegative ? '$span ago' : 'In $span';
    }
  }

  static String? _span(Duration d) {
    if (d.inMinutes < 1) return null;
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    if (d.inHours < 24) {
      final minutes = d.inMinutes % 60;
      return minutes == 0 ? '${d.inHours} hr' : '${d.inHours} hr $minutes min';
    }
    return '${d.inDays} ${d.inDays == 1 ? 'day' : 'days'}';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({super.key, required this.status});
  final ReminderOccurrenceStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (status) {
      ReminderOccurrenceStatus.upcoming => (
        AleraColors.selected,
        Icons.schedule,
      ),
      ReminderOccurrenceStatus.due => (AleraColors.warningStrong, Icons.alarm),
      ReminderOccurrenceStatus.snoozed => (
        AleraColors.warningStrong,
        Icons.snooze,
      ),
      ReminderOccurrenceStatus.completed => (
        AleraColors.successStrong,
        Icons.check_circle,
      ),
      ReminderOccurrenceStatus.completedLate => (
        AleraColors.successStrong,
        Icons.check_circle,
      ),
      ReminderOccurrenceStatus.missed => (
        AleraColors.criticalStrong,
        Icons.error,
      ),
      ReminderOccurrenceStatus.canceled => (
        AleraColors.textSecondary,
        Icons.cancel,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            reminderTitleCase(status.apiValue),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AleraColors.selected.withValues(alpha: 0.12),
          ),
          child: Icon(icon, size: 16, color: AleraColors.selected),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 92,
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              label,
              style: AleraTypography.body.copyWith(
                color: AleraColors.textSecondary,
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              value,
              style: AleraTypography.body.copyWith(
                color: AleraColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
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
  const ReminderActionDivider({super.key});

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    thickness: 1,
    indent: 16,
    endIndent: 16,
    color: AleraColors.divider,
  );
}
