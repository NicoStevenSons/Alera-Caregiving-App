import 'package:flutter/material.dart';

import '../../../design_system/alera_colors.dart';
import '../../../design_system/alera_typography.dart';
import '../../../design_system/widgets/alera_button.dart';
import '../../../design_system/widgets/alera_card.dart';
import '../../../design_system/widgets/alera_text_field.dart';
import '../domain/reminder_models.dart';
import 'reminder_formatters.dart';
import 'reminder_time_picker.dart';

/// Full-screen "New reminder" form. Pops with a [ReminderTemplateDraft] when
/// saved, or null if the caregiver backs out. Uses the shared Alera inputs
/// (the same fields as Add Patient).
class CreateReminderPage extends StatefulWidget {
  const CreateReminderPage({
    super.key,
    required this.patientId,
    required this.initialDate,
    this.patientName,
    this.now,
  });

  final String patientId;
  final DateTime initialDate;
  final String? patientName;

  /// Overridable clock for tests.
  final DateTime Function()? now;

  @override
  State<CreateReminderPage> createState() => _CreateReminderPageState();
}

class _CreateReminderPageState extends State<CreateReminderPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _instructions = TextEditingController();
  ReminderCategory _category = ReminderCategory.medication;
  ReminderPriority _priority = ReminderPriority.normal;
  ReminderNotificationChannel _channel = ReminderNotificationChannel.push;
  late DateTime _date = widget.initialDate;
  late TimeOfDay _time = TimeOfDay.fromDateTime(
    (widget.now ?? DateTime.now)(),
  );
  bool _snoozeAllowed = true;

  @override
  void dispose() {
    _title.dispose();
    _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.patientName;
    return Scaffold(
      backgroundColor: AleraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 44,
        leadingWidth: 56,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.chevron_left, size: 28),
          color: const Color(0xFFB4AEC2),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(
                'New reminder',
                style: AleraTypography.sectionTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                name == null
                    ? 'Set up a reminder for your patient.'
                    : 'Set up a reminder for $name.',
                style: AleraTypography.body.copyWith(fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 20),
              const AleraFieldLabel('Time'),
              const SizedBox(height: 6),
              ReminderTimeWheel(
                key: const Key('reminder-time-wheel'),
                initial: _time,
                onChanged: (value) => _time = value,
              ),
              const SizedBox(height: 20),
              AleraTextField(
                fieldKey: const Key('reminder-title-field'),
                controller: _title,
                label: 'Title',
                hint: 'e.g. Morning medication',
                required: true,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a reminder title.'
                    : null,
              ),
              AleraTextField(
                controller: _instructions,
                label: 'Instructions',
                hint: 'Anything the patient should know (optional)',
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
              ),
              _dropdown<ReminderCategory>(
                fieldKey: const Key('reminder-category-field'),
                label: 'Category',
                value: _category,
                values: ReminderCategory.values,
                text: (v) => reminderTitleCase(v.apiValue),
                onChanged: (v) => setState(() => _category = v),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _PickerField(
                  fieldKey: const Key('reminder-date-field'),
                  label: 'Date',
                  value: reminderShortDate(_date),
                  icon: Icons.calendar_today_outlined,
                  onTap: _pickDate,
                ),
              ),
              _dropdown<ReminderPriority>(
                fieldKey: const Key('reminder-priority-field'),
                label: 'Priority',
                value: _priority,
                values: ReminderPriority.values,
                text: (v) => reminderTitleCase(v.apiValue),
                onChanged: (v) => setState(() => _priority = v),
              ),
              _dropdown<ReminderNotificationChannel>(
                fieldKey: const Key('reminder-channel-field'),
                label: 'Notification',
                value: _channel,
                values: const [
                  ReminderNotificationChannel.push,
                  ReminderNotificationChannel.inApp,
                ],
                text: (v) => v == ReminderNotificationChannel.push
                    ? 'Push notification'
                    : 'In-app only',
                onChanged: (v) => setState(() => _channel = v),
              ),
              AleraCard(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Allow snoozing',
                            style: AleraTypography.sectionTitle.copyWith(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'The patient can ask for a few more minutes.',
                            style: AleraTypography.body.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _snoozeAllowed,
                      onChanged: (v) => setState(() => _snoozeAllowed = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AleraButton(
                      label: 'Cancel',
                      variant: AleraButtonVariant.lightPill,
                      height: 44,
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AleraButton(
                      key: const Key('save-reminder-button'),
                      label: 'Create reminder',
                      variant: AleraButtonVariant.pill,
                      height: 44,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required Key fieldKey,
    required String label,
    required T value,
    required List<T> values,
    required String Function(T) text,
    required ValueChanged<T> onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AleraFieldLabel(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          key: fieldKey,
          initialValue: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: AleraColors.fieldHint,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(fontSize: 13, color: AleraColors.textPrimary),
          decoration: aleraInputDecoration(hint: label),
          items: [
            for (final v in values)
              DropdownMenuItem(value: v, child: Text(text(v))),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
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

/// A tappable field that looks like an [AleraTextField] but opens a picker.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final Key fieldKey;
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AleraFieldLabel(label),
      const SizedBox(height: 6),
      InkWell(
        key: fieldKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: aleraInputDecoration(
            hint: label,
            suffixIcon: Icon(icon, size: 18, color: AleraColors.primary),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AleraColors.textPrimary,
            ),
          ),
        ),
      ),
    ],
  );
}
