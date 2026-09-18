import 'package:flutter/material.dart';

import '../../../design_system/alera_spacing.dart';
import '../../../design_system/widgets/alera_bottom_sheet.dart';
import '../../../design_system/widgets/alera_dialog.dart';
import '../../../design_system/widgets/alera_feedback.dart';
import '../../../design_system/widgets/alera_text_input_dialog.dart';
import '../../caregiver/domain/models/care_recipient.dart';
import '../../caregiver/presentation/widgets/caregiver_page_app_bar.dart';
import '../data/reminder_api_data_source.dart';
import '../data/reminder_controller.dart';
import '../domain/reminder_models.dart';

class CaregiverRemindersPage extends StatefulWidget {
  const CaregiverRemindersPage({
    super.key,
    required this.controller,
    required this.patients,
    this.initialPatientId,
    this.onPatientSelected,
  });

  final ReminderController controller;
  final List<CareRecipient> patients;
  final String? initialPatientId;
  final ValueChanged<String>? onPatientSelected;

  @override
  State<CaregiverRemindersPage> createState() => _CaregiverRemindersPageState();
}

class _CaregiverRemindersPageState extends State<CaregiverRemindersPage> {
  String? _patientId;

  @override
  void initState() {
    super.initState();
    _selectInitialPatient();
  }

  @override
  void didUpdateWidget(CaregiverRemindersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = widget.patients.map((patient) => patient.id).toSet();
    if (_patientId == null || !ids.contains(_patientId)) {
      _selectInitialPatient();
    } else if (widget.initialPatientId != null &&
        widget.initialPatientId != oldWidget.initialPatientId &&
        ids.contains(widget.initialPatientId)) {
      _selectPatient(widget.initialPatientId!);
    }
  }

  void _selectInitialPatient() {
    if (widget.patients.isEmpty) return;
    final requested = widget.initialPatientId;
    final selected =
        requested != null &&
            widget.patients.any((patient) => patient.id == requested)
        ? requested
        : widget.patients.first.id;
    _patientId = selected;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.loadForPatient(selected);
    });
  }

  void _selectPatient(String patientId) {
    if (_patientId == patientId) return;
    setState(() => _patientId = patientId);
    widget.onPatientSelected?.call(patientId);
    widget.controller.loadForPatient(patientId);
  }

  @override
  Widget build(BuildContext context) {
    final patientId = _patientId;
    return Scaffold(
      appBar: CaregiverPageAppBar(
        title: 'Reminders',
        actions: [
          caregiverPageAction(
            tooltip: 'Refresh reminders',
            onPressed: patientId == null ? () {} : widget.controller.refresh,
            icon: Icons.refresh,
          ),
        ],
      ),
      floatingActionButton: patientId == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('create-reminder-button'),
              onPressed: () => _showCreateReminder(context, patientId),
              icon: const Icon(Icons.add),
              label: const Text('New reminder'),
            ),
      body: widget.patients.isEmpty
          ? const _MessageState(
              icon: Icons.person_search_outlined,
              message: 'Add or connect a patient before creating reminders.',
            )
          : AnimatedBuilder(
              animation: widget.controller,
              builder: (context, _) => RefreshIndicator(
                onRefresh: widget.controller.refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AleraSpacing.medium,
                    AleraSpacing.small,
                    AleraSpacing.medium,
                    104,
                  ),
                  children: [
                    _PatientPicker(
                      patients: widget.patients,
                      patientId: patientId!,
                      onChanged: _selectPatient,
                    ),
                    const SizedBox(height: AleraSpacing.medium),
                    if (widget.controller.loading)
                      const LinearProgressIndicator(
                        key: Key('reminder-loading'),
                      ),
                    if (widget.controller.errorMessage case final message?) ...[
                      const SizedBox(height: AleraSpacing.small),
                      _ErrorBanner(
                        message: message,
                        onRetry: widget.controller.refresh,
                      ),
                    ],
                    const SizedBox(height: AleraSpacing.medium),
                    Text(
                      'Scheduled occurrences',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AleraSpacing.small),
                    if (!widget.controller.loading &&
                        widget.controller.occurrences.isEmpty)
                      const _EmptyCard(
                        key: Key('reminder-occurrences-empty'),
                        message: 'No scheduled reminders for this patient.',
                      )
                    else
                      for (final occurrence
                          in widget.controller.occurrences) ...[
                        _OccurrenceCard(
                          occurrence: occurrence,
                          busy: widget.controller.isBusy(occurrence.id),
                          onComplete: () => _complete(occurrence),
                          onSnooze: () => _snooze(occurrence),
                          onCancel: () => _cancel(occurrence),
                        ),
                        const SizedBox(height: AleraSpacing.small),
                      ],
                    const SizedBox(height: AleraSpacing.medium),
                    Text(
                      'Reminder schedules',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AleraSpacing.small),
                    if (!widget.controller.loading &&
                        widget.controller.templates.isEmpty)
                      const _EmptyCard(
                        key: Key('reminder-templates-empty'),
                        message: 'No reminder schedules yet.',
                      )
                    else
                      for (final template in widget.controller.templates) ...[
                        _TemplateCard(
                          template: template,
                          busy: widget.controller.isTemplateBusy(template.id),
                          onArchive:
                              template.status == ReminderTemplateStatus.archived
                              ? null
                              : () => _archive(template),
                        ),
                        const SizedBox(height: AleraSpacing.small),
                      ],
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _complete(ReminderOccurrence occurrence) async {
    final note = await _askForNote(
      title: 'Complete for patient',
      hint: 'Why are you completing this on their behalf?',
      actionLabel: 'Complete',
    );
    if (note == null) return;
    await _run(() => widget.controller.completeOnBehalf(occurrence.id, note));
  }

  Future<void> _snooze(ReminderOccurrence occurrence) async {
    final note = await _askForNote(
      title: 'Snooze for patient',
      hint: 'Why does the patient need more time?',
      actionLabel: 'Snooze',
    );
    if (note == null) return;
    await _run(
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
      title: 'Cancel occurrence',
      hint: 'Reason for cancellation',
      actionLabel: 'Cancel reminder',
    );
    if (note == null) return;
    await _run(() => widget.controller.cancel(occurrence.id, note));
  }

  Future<void> _archive(ReminderTemplate template) async {
    final confirmed = await showAleraConfirmDialog(
      context: context,
      title: 'Archive schedule?',
      message: 'Future occurrences for “${template.title}” will be canceled.',
      cancelLabel: 'Keep',
      confirmLabel: 'Archive',
      destructive: true,
    );
    if (confirmed) {
      await _run(() => widget.controller.archiveTemplate(template.id));
    }
  }

  Future<String?> _askForNote({
    required String title,
    required String hint,
    required String actionLabel,
  }) => showAleraTextInputDialog(
    context: context,
    title: title,
    fieldLabel: hint,
    submitLabel: actionLabel,
    cancelLabel: 'Back',
    fieldKey: const Key('reminder-action-note'),
  );

  Future<void> _run(
    Future<void> Function() operation, {
    String success = 'Reminder updated.',
  }) async {
    try {
      await operation();
      if (!mounted) return;
      AleraFeedback.success(context, success);
    } on ReminderApiFailure catch (error) {
      if (!mounted || error.statusCode == 401) return;
      AleraFeedback.error(context, error.message);
    }
  }

  Future<void> _showCreateReminder(
    BuildContext context,
    String patientId,
  ) async {
    final draft = await showAleraBottomSheet<ReminderTemplateDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CreateReminderSheet(patientId: patientId),
    );
    if (draft == null) return;
    await _run(
      () => widget.controller.createTemplate(draft),
      success: 'Reminder created.',
    );
  }
}

class _PatientPicker extends StatelessWidget {
  const _PatientPicker({
    required this.patients,
    required this.patientId,
    required this.onChanged,
  });

  final List<CareRecipient> patients;
  final String patientId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    key: const Key('reminder-patient-picker'),
    initialValue: patientId,
    decoration: const InputDecoration(
      labelText: 'Patient',
      prefixIcon: Icon(Icons.person_outline),
      border: OutlineInputBorder(),
    ),
    items: [
      for (final patient in patients)
        DropdownMenuItem(value: patient.id, child: Text(patient.name)),
    ],
    onChanged: (value) {
      if (value != null) onChanged(value);
    },
  );
}

class _OccurrenceCard extends StatelessWidget {
  const _OccurrenceCard({
    required this.occurrence,
    required this.busy,
    required this.onComplete,
    required this.onSnooze,
    required this.onCancel,
  });

  final ReminderOccurrence occurrence;
  final bool busy;
  final VoidCallback onComplete;
  final VoidCallback onSnooze;
  final VoidCallback onCancel;

  bool get _actionable => switch (occurrence.status) {
    ReminderOccurrenceStatus.upcoming ||
    ReminderOccurrenceStatus.due ||
    ReminderOccurrenceStatus.snoozed => true,
    _ => false,
  };

  @override
  Widget build(BuildContext context) => Card(
    key: ValueKey('reminder-occurrence-${occurrence.id}'),
    child: Padding(
      padding: const EdgeInsets.all(AleraSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  occurrence.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _StatusChip(label: _label(occurrence.status.apiValue)),
            ],
          ),
          const SizedBox(height: AleraSpacing.xSmall),
          Text(_formatDateTime(occurrence.scheduledAt)),
          if (occurrence.instructions case final instructions?) ...[
            const SizedBox(height: AleraSpacing.xSmall),
            Text(instructions),
          ],
          if (_actionable) ...[
            const SizedBox(height: AleraSpacing.small),
            if (busy)
              const LinearProgressIndicator()
            else
              Wrap(
                spacing: AleraSpacing.small,
                runSpacing: AleraSpacing.xSmall,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.check),
                    label: const Text('Complete'),
                  ),
                  if (occurrence.snoozeAllowed)
                    OutlinedButton.icon(
                      onPressed: onSnooze,
                      icon: const Icon(Icons.snooze),
                      label: const Text('Snooze'),
                    ),
                  TextButton(onPressed: onCancel, child: const Text('Cancel')),
                ],
              ),
          ],
        ],
      ),
    ),
  );
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.busy,
    required this.onArchive,
  });

  final ReminderTemplate template;
  final bool busy;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) => Card(
    key: ValueKey('reminder-template-${template.id}'),
    child: ListTile(
      title: Text(template.title),
      subtitle: Text(
        '${template.startDate} at ${template.startTime.substring(0, 5)}'
        '${template.scheduleRule == null ? '' : ' • Repeats'}',
      ),
      trailing: busy
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'archive') onArchive?.call();
              },
              itemBuilder: (context) => [
                if (onArchive != null)
                  const PopupMenuItem(
                    value: 'archive',
                    child: Text('Archive schedule'),
                  ),
              ],
            ),
    ),
  );
}

class _CreateReminderSheet extends StatefulWidget {
  const _CreateReminderSheet({required this.patientId});
  final String patientId;

  @override
  State<_CreateReminderSheet> createState() => _CreateReminderSheetState();
}

class _CreateReminderSheetState extends State<_CreateReminderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _instructions = TextEditingController();
  ReminderCategory _category = ReminderCategory.medication;
  ReminderPriority _priority = ReminderPriority.normal;
  ReminderNotificationChannel _channel = ReminderNotificationChannel.push;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _snoozeAllowed = true;

  @override
  void dispose() {
    _title.dispose();
    _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AleraBottomSheetShell(
    title: 'Create reminder',
    child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            TextFormField(
              key: const Key('reminder-title-field'),
              controller: _title,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a reminder title.'
                  : null,
            ),
            const SizedBox(height: AleraSpacing.small),
            TextFormField(
              controller: _instructions,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Instructions (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AleraSpacing.small),
            DropdownButtonFormField<ReminderCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final category in ReminderCategory.values)
                  DropdownMenuItem(
                    value: category,
                    child: Text(_label(category.apiValue)),
                  ),
              ],
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: AleraSpacing.small),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(_formatDate(_date)),
                  ),
                ),
                const SizedBox(width: AleraSpacing.small),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(_time.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AleraSpacing.small),
            DropdownButtonFormField<ReminderPriority>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final priority in ReminderPriority.values)
                  DropdownMenuItem(
                    value: priority,
                    child: Text(_label(priority.apiValue)),
                  ),
              ],
              onChanged: (value) => setState(() => _priority = value!),
            ),
            const SizedBox(height: AleraSpacing.small),
            DropdownButtonFormField<ReminderNotificationChannel>(
              initialValue: _channel,
              decoration: const InputDecoration(
                labelText: 'Notification',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: ReminderNotificationChannel.push,
                  child: Text('Push notification'),
                ),
                DropdownMenuItem(
                  value: ReminderNotificationChannel.inApp,
                  child: Text('In-app only'),
                ),
              ],
              onChanged: (value) => setState(() => _channel = value!),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Allow snoozing'),
              value: _snoozeAllowed,
              onChanged: (value) => setState(() => _snoozeAllowed = value),
            ),
            const SizedBox(height: AleraSpacing.small),
            FilledButton.icon(
              key: const Key('save-reminder-button'),
              onPressed: _submit,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Create reminder'),
            ),
          ],
        ),
    ),
  );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ReminderTemplateDraft(
        patientId: widget.patientId,
        title: _title.text,
        instructions: _instructions.text.trim().isEmpty
            ? null
            : _instructions.text,
        category: _category,
        priority: _priority,
        startDate: _apiDate(_date),
        startTime:
            '${_time.hour.toString().padLeft(2, '0')}:'
            '${_time.minute.toString().padLeft(2, '0')}:00',
        snoozeAllowed: _snoozeAllowed,
        notificationChannel: _channel,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) =>
      Chip(label: Text(label), visualDensity: VisualDensity.compact);
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.errorContainer,
    borderRadius: BorderRadius.circular(AleraSpacing.cardRadius),
    child: ListTile(
      leading: const Icon(Icons.error_outline),
      title: Text(message),
      trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AleraSpacing.medium),
      child: Text(message),
    ),
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AleraSpacing.large),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: AleraSpacing.small),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

String _label(String value) => value
    .toLowerCase()
    .split('_')
    .map(
      (part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
    )
    .join(' ');

String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';

String _apiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour == 0
      ? 12
      : local.hour > 12
      ? local.hour - 12
      : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${_formatDate(local)} • $hour:$minute $period';
}
