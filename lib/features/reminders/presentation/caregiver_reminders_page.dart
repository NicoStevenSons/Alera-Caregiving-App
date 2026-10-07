import 'package:flutter/material.dart';

import '../../../design_system/alera_colors.dart';
import '../../../design_system/alera_typography.dart';
import '../../../design_system/widgets/alera_card.dart';
import '../../../design_system/widgets/alera_date_picker.dart';
import '../../../design_system/widgets/alera_empty_state.dart';
import '../../../design_system/widgets/alera_patient_avatar.dart';
import '../../../design_system/widgets/alera_skeleton.dart';
import '../../caregiver/domain/models/care_recipient.dart';
import '../../caregiver/presentation/widgets/caregiver_page_app_bar.dart';
import '../data/reminder_api_data_source.dart';
import '../data/reminder_controller.dart';
import '../domain/reminder_models.dart';
import 'create_reminder_sheet.dart';
import 'reminder_action_runner.dart';
import 'reminder_formatters.dart';
import 'reminder_note_dialog.dart';
import 'reminder_occurrence_detail_page.dart';
import 'reminder_schedules_page.dart';
import 'widgets/reminder_date_strip.dart';
import 'widgets/reminder_date_header.dart';
import 'widgets/reminder_summary_card.dart';
import 'widgets/reminder_timeline.dart';

/// Day-by-day reminder timeline for the patient selected in the caregiver
/// shell. The shell owns patient selection; the patient chip at the top just
/// opens its switcher when there is more than one patient.
class CaregiverRemindersPage extends StatefulWidget {
  const CaregiverRemindersPage({
    super.key,
    required this.controller,
    required this.patients,
    this.initialPatientId,
    this.onSwitchPatient,
    this.eventsDataSource,
    this.now,
  });

  final ReminderController controller;
  final List<CareRecipient> patients;
  final String? initialPatientId;

  /// Opens the shell's patient switcher; null when there is only one patient.
  final VoidCallback? onSwitchPatient;
  /// Where the occurrence timeline is read from. Defaults to the real API
  /// when not injected (tests inject a fake).
  final ReminderEventsDataSource? eventsDataSource;

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

  String? get _patientPhoto {
    for (final patient in widget.patients) {
      if (patient.id == _patientId) return patient.profilePhotoUrl;
    }
    return null;
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (name != null)
                  Expanded(
                    child: _PatientChip(
                      name: name,
                      photoUrl: _patientPhoto,
                      onTap: widget.onSwitchPatient,
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 10),
                _CalendarButton(onTap: _pickDate),
              ],
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: ReminderSummaryCard(
                occurrences: dayItems,
                isToday: isToday,
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
    final Widget content;
    if (controller.loading && controller.occurrences.isEmpty) {
      content = const _TimelineSkeleton(key: Key('reminder-loading'));
    } else if (dayItems.isEmpty) {
      content = const _MutedState(
        key: Key('reminder-occurrences-empty'),
        icon: Icons.alarm_off,
        title: 'No reminders for this day',
        message: 'Tap + to add one.',
      );
    } else {
      content = ReminderTimeline(
        occurrences: dayItems,
        templates: controller.templates,
        isBusy: controller.isBusy,
        onComplete: _complete,
        onOpen: _openActions,
        now: isToday ? (widget.now ?? DateTime.now)() : null,
      );
    }
    return AleraCard(
      key: const Key('reminder-list-card'),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: ReminderDateHeader(
              date: _selectedDay,
              isToday: isToday,
              onToday: () => setState(() => _selectedDay = _today),
            ),
          ),
          content,
        ],
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

  /// Card tap: opens the occurrence detail page (info, actions, timeline).
  Future<void> _openActions(ReminderOccurrence occurrence) async {
    final events = widget.eventsDataSource ?? ReminderApiDataSource();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ReminderOccurrenceDetailPage(
          occurrence: occurrence,
          controller: widget.controller,
          eventsDataSource: events,
          onComplete: _complete,
          onSnooze: _snooze,
          onCancel: _cancel,
        ),
      ),
    );
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

/// "Who these reminders are for": avatar + name, with a dropdown arrow and tap
/// to switch when the caregiver has more than one patient.
class _PatientChip extends StatelessWidget {
  const _PatientChip({required this.name, this.photoUrl, this.onTap});

  final String name;
  final String? photoUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AleraCard(
      key: const Key('reminder-patient-chip'),
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      child: Row(
        children: [
          AleraPatientAvatar(name: name, photoUrl: photoUrl, radius: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              key: const Key('reminder-patient-subtitle'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AleraTypography.sectionTitle.copyWith(fontSize: 15),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: AleraColors.selected,
            ),
          ],
        ],
      ),
    );
  }
}

/// Opens the calendar to jump to any date (e.g. to book ahead).
class _CalendarButton extends StatelessWidget {
  const _CalendarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AleraCard(
      key: const Key('reminder-pick-date'),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: const SizedBox(
        height: 40,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month, size: 20, color: AleraColors.selected),
            SizedBox(width: 6),
            Text(
              'Calendar',
              style: TextStyle(
                color: AleraColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
