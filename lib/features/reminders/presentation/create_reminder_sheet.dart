import 'package:flutter/material.dart';

import '../../../design_system/alera_spacing.dart';
import '../domain/reminder_models.dart';
import 'reminder_formatters.dart';

String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';

class CreateReminderSheet extends StatefulWidget {
  const CreateReminderSheet({
    super.key,
    required this.patientId,
    required this.initialDate,
  });
  final String patientId;
  final DateTime initialDate;

  @override
  State<CreateReminderSheet> createState() => CreateReminderSheetState();
}

class CreateReminderSheetState extends State<CreateReminderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _instructions = TextEditingController();
  ReminderCategory _category = ReminderCategory.medication;
  ReminderPriority _priority = ReminderPriority.normal;
  ReminderNotificationChannel _channel = ReminderNotificationChannel.push;
  late DateTime _date = widget.initialDate;
  TimeOfDay _time = TimeOfDay.now();
  bool _snoozeAllowed = true;

  @override
  void dispose() {
    _title.dispose();
    _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        AleraSpacing.medium,
        0,
        AleraSpacing.medium,
        MediaQuery.viewInsetsOf(context).bottom + AleraSpacing.medium,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              'Create reminder',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AleraSpacing.medium),
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
                    child: Text(reminderTitleCase(category.apiValue)),
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
                    child: Text(reminderTitleCase(priority.apiValue)),
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
    ),
  );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
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
        startDate: reminderApiDate(_date),
        startTime:
            '${_time.hour.toString().padLeft(2, '0')}:'
            '${_time.minute.toString().padLeft(2, '0')}:00',
        snoozeAllowed: _snoozeAllowed,
        notificationChannel: _channel,
      ),
    );
  }
}

