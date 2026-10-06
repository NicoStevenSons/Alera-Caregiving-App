import 'package:flutter/material.dart';

import '../../../design_system/alera_colors.dart';
import '../../../design_system/alera_typography.dart';
import '../../../design_system/widgets/alera_card.dart';
import '../../../design_system/widgets/alera_date_picker.dart';
import '../../../design_system/widgets/alera_empty_state.dart';
import '../../../design_system/widgets/alera_pill.dart';
import '../../../design_system/widgets/alera_skeleton.dart';
import '../../caregiver/domain/models/care_recipient.dart';
import '../../caregiver/presentation/widgets/caregiver_page_app_bar.dart';
import '../data/reminder_controller.dart';
import '../domain/reminder_models.dart';
import 'create_reminder_sheet.dart';
import 'reminder_action_runner.dart';
import 'reminder_formatters.dart';
import 'reminder_note_dialog.dart';
import 'reminder_schedules_page.dart';
import 'widgets/reminder_date_strip.dart';
import 'widgets/reminder_summary_card.dart';
import 'widgets/reminder_timeline.dart';
import '../../../design_system/alera_sheet_animation.dart';

/// Day-by-day reminder timeline for the patient selected in the caregiver
/// shell. There is no patient picker here: the shell (and the dashboard) own
/// patient selection, and this page just follows it.
class CaregiverRemindersPage extends StatefulWidget {
  const CaregiverRemindersPage({
    super.key,
    required this.controller,
    required this.patients,
    this.initialPatientId,
    this.now,
  });

  final ReminderController controller;
  final List<CareRecipient> patients;
  final String? initialPatientId;

  /// Overridable clock for tests.
  final DateTime Function()? now;

  @override
  State<CaregiverRemindersPage> createState() => _CaregiverRemindersPageState();
}

class _CaregiverRemindersPageState extends State<CaregiverRemindersPage> {
  String? _patientId;
  late DateTime _today;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = (widget.now ?? DateTime.now)();
    _today = DateTime(now.year, now.month, now.day);
    _selectedDay = _today;
    _syncPatient();
  }

  @override
  void didUpdateWidget(CaregiverRemindersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = widget.patients.map((patient) => patient.id).toSet();
    final requested = widget.initialPatientId;
    if (_patientId == null || !ids.contains(_patientId)) {
      _syncPatient();
    } else if (requested != null &&
        requested != _patientId &&
        ids.contains(requested)) {
      _syncPatient();
    }
  }

  void _syncPatient() {
    if (widget.patients.isEmpty) return;
    final requested = widget.initialPatientId;
    final selected =
        requested != null &&
            widget.patients.any((patient) => patient.id == requested)
        ? requested
        : widget.patients.first.id;
    if (selected == _patientId) return;
    _patientId = selected;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _patientId == selected) {
        widget.controller.loadForPatient(selected);
      }
    });
  }

  String? get _patientName {
    for (final patient in widget.patients) {
      if (patient.id == _patientId) return patient.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final patientId = _patientId;
    return Scaffold(
      backgroundColor: AleraColors.background,
      appBar: CaregiverPageAppBar(
        title: 'Reminders',
        actions: [
          caregiverPageAction(
            key: const Key('reminder-pick-date'),
            tooltip: 'Pick a date',
            onPressed: patientId == null ? () {} : _pickDate,
            icon: Icons.calendar_month,
          ),
          caregiverPageAction(
            tooltip: 'Manage schedules',
            onPressed: patientId == null ? () {} : _openSchedules,
            icon: Icons.event_repeat,
          ),
          caregiverPageAction(
            tooltip: 'Refresh reminders',
            onPressed: patientId == null ? () {} : widget.controller.refresh,
            icon: Icons.refresh,
          ),
        ],
      ),
      floatingActionButton: patientId == null
          ? null
          : FloatingActionButton(
              key: const Key('create-reminder-button'),
              tooltip: 'New reminder',
              shape: const CircleBorder(),
              backgroundColor: AleraColors.selected,
              foregroundColor: Colors.white,
              onPressed: () => _showCreateReminder(patientId),
              child: const Icon(Icons.add, size: 28),
            ),
      body: widget.patients.isEmpty
          ? const _MutedState(
              icon: Icons.person_search,
              title: 'No patient selected',
              message: 'Add or connect a patient before creating reminders.',
            )
          : AnimatedBuilder(
              animation: widget.controller,
              builder: (context, _) => _buildBody(context),
            ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final controller = widget.controller;
    final byDay = <DateTime, List<ReminderOccurrence>>{};
    for (final occurrence in controller.occurrences) {
      byDay
          .putIfAbsent(reminderDayOf(occurrence.scheduledAt), () => [])
          .add(occurrence);
    }
    final dayItems = [...?byDay[_selectedDay]]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final isToday = _selectedDay == _today;
    final name = _patientName;

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 12, bottom: 104),
        children: [
          if (name != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '$name’s daily reminders',
                key: const Key('reminder-patient-subtitle'),
                style: AleraTypography.body.copyWith(
                  color: AleraColors.textSecondary,
                ),
              ),
            ),
          const SizedBox(height: 8),
          ReminderDateStrip(
            today: _today,
            selected: _selectedDay,
            markedDays: byDay.keys.toSet(),
            onSelected: (day) => setState(() => _selectedDay = day),
          ),
          if (!(controller.loading && controller.occurrences.isEmpty))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ReminderSummaryCard(
                occurrences: dayItems,
                isToday: isToday,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    reminderLongDate(_selectedDay),
                    key: const Key('reminder-selected-date'),
                    style: AleraTypography.pageTitle.copyWith(fontSize: 20),
                  ),
                ),
                AleraPill(
                  key: const Key('reminder-today-pill'),
                  label: 'Today',
                  variant: isToday
                      ? AleraPillVariant.label
                      : AleraPillVariant.action,
                  onTap: isToday
                      ? null
                      : () => setState(() => _selectedDay = _today),
                ),
              ],
            ),
          ),
          if (controller.errorMessage case final message?)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _ErrorCard(message: message, onRetry: controller.refresh),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _timeline(controller, dayItems, isToday),
          ),
        ],
      ),
    );
  }

  Widget _timeline(
    ReminderController controller,
    List<ReminderOccurrence> dayItems,
    bool isToday,
  ) {
    if (controller.loading && controller.occurrences.isEmpty) {
      return const _TimelineSkeleton(key: Key('reminder-loading'));
    }
    if (dayItems.isEmpty) {
      return const _MutedState(
        key: Key('reminder-occurrences-empty'),
        icon: Icons.alarm_off,
        title: 'No reminders for this day',
        message: 'Tap + to add one.',
      );
    }
    return AleraCard(
      key: const Key('reminder-list-card'),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: ReminderTimeline(
      occurrences: dayItems,
      templates: controller.templates,
      isBusy: controller.isBusy,
      onComplete: _complete,
      onOpen: _openActions,
      now: isToday ? (widget.now ?? DateTime.now)() : null,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showAleraDatePicker(
      context,
      initialDate: _selectedDay,
      firstDate: _today.subtract(const Duration(days: 365)),
      lastDate: _today.add(const Duration(days: 365 * 2)),
    );
    if (picked == null || !mounted) return;
    setState(
      () => _selectedDay = DateTime(picked.year, picked.month, picked.day),
    );
  }

  void _openSchedules() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReminderSchedulesPage(
          controller: widget.controller,
          patientName: _patientName,
        ),
      ),
    );
  }

  Future<void> _complete(ReminderOccurrence occurrence) async {
    final note = await _askForNote(
      icon: Icons.check_circle,
      title: 'Complete for patient',
      hint: 'Why are you completing this on their behalf?',
      actionLabel: 'Complete',
    );
    if (note == null || !mounted) return;
    await runReminderAction(
      context,
      () => widget.controller.completeOnBehalf(occurrence.id, note),
    );
  }

  Future<void> _snooze(ReminderOccurrence occurrence) async {
    final note = await _askForNote(
      icon: Icons.snooze,
      title: 'Snooze for patient',
      hint: 'Why does the patient need more time?',
      actionLabel: 'Snooze',
    );
    if (note == null || !mounted) return;
    await runReminderAction(
      context,
      () => widget.controller.snoozeOnBehalf(
        occurrence.id,
        note,
        minutes: occurrence.defaultSnoozeMinutes,
      ),
      success:
          'Reminder snoozed for ${occurrence.defaultSnoozeMinutes} minutes.',
    );
  }

  Future<void> _cancel(ReminderOccurrence occurrence) async {
    final note = await _askForNote(
      icon: Icons.event_busy,
      title: 'Cancel reminder',
      hint: 'Reason for cancellation',
      actionLabel: 'Cancel reminder',
    );
    if (note == null || !mounted) return;
    await runReminderAction(
      context,
      () => widget.controller.cancel(occurrence.id, note),
    );
  }

  /// Card tap: the less common actions (snooze / cancel) live in a sheet so
  /// the card itself stays as clean as the mock.
  Future<void> _openActions(ReminderOccurrence occurrence) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      sheetAnimationStyle: aleraSheetAnimation,
      backgroundColor: AleraColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      occurrence.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AleraTypography.sectionTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reminderClock(occurrence.scheduledAt),
                      style: AleraTypography.body.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              AleraCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ActionRow(
                      key: const Key('reminder-action-complete'),
                      icon: Icons.check_circle,
                      label: 'Mark complete',
                      onTap: () => Navigator.pop(context, 'complete'),
                    ),
                    if (occurrence.snoozeAllowed) ...[
                      const _ActionDivider(),
                      _ActionRow(
                        key: const Key('reminder-action-snooze'),
                        icon: Icons.snooze,
                        label: 'Snooze ${occurrence.defaultSnoozeMinutes} minutes',
                        onTap: () => Navigator.pop(context, 'snooze'),
                      ),
                    ],
                    const _ActionDivider(),
                    _ActionRow(
                      key: const Key('reminder-action-cancel'),
                      icon: Icons.event_busy,
                      label: 'Cancel this reminder',
                      destructive: true,
                      onTap: () => Navigator.pop(context, 'cancel'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'complete':
        await _complete(occurrence);
      case 'snooze':
        await _snooze(occurrence);
      case 'cancel':
        await _cancel(occurrence);
    }
  }

  Future<String?> _askForNote({
    required IconData icon,
    required String title,
    required String hint,
    required String actionLabel,
  }) => showReminderNoteDialog(
    context,
    icon: icon,
    title: title,
    hint: hint,
    actionLabel: actionLabel,
  );

  Future<void> _showCreateReminder(String patientId) async {
    final draft = await showCreateReminderSheet(
      context,
      patientId: patientId,
      patientName: _patientName,
      initialDate: _selectedDay,
      now: widget.now,
    );
    if (draft == null || !mounted) return;
    await runReminderAction(
      context,
      () => widget.controller.createTemplate(draft),
      success: 'Reminder created.',
    );
  }
}

class _TimelineSkeleton extends StatelessWidget {
  const _TimelineSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < 3; i++)
        const Padding(
          padding: EdgeInsets.only(bottom: 12, left: 68),
          child: AleraSkeletonBlock(height: 76),
        ),
    ],
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => AleraCard(
    child: Row(
      children: [
        const Icon(Icons.error, color: AleraColors.critical),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: AleraTypography.body)),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

/// Same muted-grey motif as the "No active alerts" empty state.
class _MutedState extends StatelessWidget {
  const _MutedState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) =>
      AleraEmptyState(icon: icon, title: title, message: message);
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
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
    final color = destructive ? AleraColors.critical : AleraColors.primary;
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

class _ActionDivider extends StatelessWidget {
  const _ActionDivider();

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    thickness: 1,
    indent: 16,
    endIndent: 16,
    color: AleraColors.divider,
  );
}
