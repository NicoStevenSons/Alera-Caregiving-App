import 'package:flutter/material.dart';

import '../../../design_system/alera_colors.dart';
import '../../../design_system/alera_typography.dart';
import '../../../design_system/widgets/alera_card.dart';
import '../../../design_system/widgets/alera_pill.dart';
import '../../../design_system/widgets/alera_text_field.dart';
import '../domain/reminder_models.dart';
import 'reminder_formatters.dart';
import 'reminder_repeat.dart';
import 'reminder_time_picker.dart';

/// Pull-up "New reminder" drawer, laid out like the phone's New alarm
/// screen: a live "Reminds in…" line, the time wheel, a repeat selector,
/// then Alera cards holding the inputs. Pops with a [ReminderTemplateDraft]
/// when saved.
Future<ReminderTemplateDraft?> showCreateReminderSheet(
  BuildContext context, {
  required String patientId,
  required DateTime initialDate,
  String? patientName,
  DateTime Function()? now,
}) => showModalBottomSheet<ReminderTemplateDraft>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: AleraColors.background,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (context) => FractionallySizedBox(
    heightFactor: 0.94,
    child: CreateReminderSheet(
      patientId: patientId,
      patientName: patientName,
      initialDate: initialDate,
      now: now,
    ),
  ),
);

class CreateReminderSheet extends StatefulWidget {
  const CreateReminderSheet({
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
  State<CreateReminderSheet> createState() => _CreateReminderSheetState();
}

class _CreateReminderSheetState extends State<CreateReminderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _instructions = TextEditingController();
  ReminderCategory _category = ReminderCategory.medication;
  ReminderPriority _priority = ReminderPriority.normal;
  ReminderNotificationChannel _channel = ReminderNotificationChannel.push;
  ReminderRepeat _repeat = const ReminderRepeat();
  late DateTime _date = widget.initialDate;
  late TimeOfDay _time = TimeOfDay.fromDateTime(_now());
  bool _snoozeAllowed = true;
  bool _customDaysError = false;

  DateTime _now() => (widget.now ?? DateTime.now)();

  @override
  void dispose() {
    _title.dispose();
    _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = _now();
    final until = reminderUntilText(
      reminderNextFire(
        repeat: _repeat,
        startDate: _date,
        time: _time,
        now: now,
      ),
      now,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: Row(
            children: [
              TextButton(
                key: const Key('reminder-create-cancel'),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              Expanded(
                child: Text(
                  'New reminder',
                  textAlign: TextAlign.center,
                  style: AleraTypography.sectionTitle.copyWith(fontSize: 16),
                ),
              ),
              TextButton(
                key: const Key('save-reminder-button'),
                onPressed: _submit,
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                4,
                16,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              children: [
                Text(
                  until,
                  key: const Key('reminder-time-until'),
                  textAlign: TextAlign.center,
                  style: AleraTypography.body.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 10),
                ReminderTimeWheel(
                  key: const Key('reminder-time-wheel'),
                  initial: _time,
                  onChanged: (value) => setState(() => _time = value),
                ),
                const SizedBox(height: 16),
                _repeatPills(),
                if (_repeat.mode == ReminderRepeatMode.custom) ...[
                  const SizedBox(height: 12),
                  _dayPicker(),
                ],
                const SizedBox(height: 16),
                AleraCard(
                  child: Column(
                    children: [
                      AleraTextField(
                        fieldKey: const Key('reminder-title-field'),
                        controller: _title,
                        label: 'Title',
                        hint: 'e.g. Morning medication',
                        required: true,
                        textCapitalization: TextCapitalization.sentences,
                        bottomSpacing: 14,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter a reminder title.'
                            : null,
                      ),
                      AleraTextField(
                        controller: _instructions,
                        label: 'Instructions',
                        hint: 'Anything the patient should know (optional)',
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                        bottomSpacing: 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AleraCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      _SettingRow(
                        label: _repeat.repeats ? 'Starts' : 'Date',
                        onTap: _pickDate,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              key: const Key('reminder-date-field'),
                              reminderShortDate(_date),
                              style: _valueStyle,
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: AleraColors.primary,
                            ),
                          ],
                        ),
                      ),
                      const _RowDivider(),
                      _dropdownRow<ReminderCategory>(
                        fieldKey: const Key('reminder-category-field'),
                        label: 'Category',
                        value: _category,
                        values: ReminderCategory.values,
                        text: (v) => reminderTitleCase(v.apiValue),
                        onChanged: (v) => setState(() => _category = v),
                      ),
                      const _RowDivider(),
                      _dropdownRow<ReminderPriority>(
                        fieldKey: const Key('reminder-priority-field'),
                        label: 'Priority',
                        value: _priority,
                        values: ReminderPriority.values,
                        text: (v) => reminderTitleCase(v.apiValue),
                        onChanged: (v) => setState(() => _priority = v),
                      ),
                      const _RowDivider(),
                      _dropdownRow<ReminderNotificationChannel>(
                        fieldKey: const Key('reminder-channel-field'),
                        label: 'Notification',
                        value: _channel,
                        values: const [
                          ReminderNotificationChannel.push,
                          ReminderNotificationChannel.inApp,
                        ],
                        text: (v) => v == ReminderNotificationChannel.push
                            ? 'Push'
                            : 'In-app only',
                        onChanged: (v) => setState(() => _channel = v),
                      ),
                      const _RowDivider(),
                      _SettingRow(
                        label: 'Allow snoozing',
                        child: Switch(
                          value: _snoozeAllowed,
                          onChanged: (v) => setState(() => _snoozeAllowed = v),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static const _valueStyle = TextStyle(
    fontSize: 13,
    color: AleraColors.textPrimary,
  );

  Widget _repeatPills() {
    Widget pill(String label, ReminderRepeatMode mode, Key key) => Expanded(
      child: Center(
        child: AleraPill(
          key: key,
          label: label,
          variant: AleraPillVariant.filter,
          selected: _repeat.mode == mode,
          onTap: () => setState(() {
            _repeat = _repeat.copyWith(mode: mode);
            _customDaysError = false;
          }),
        ),
      ),
    );
    return Row(
      children: [
        pill('Once', ReminderRepeatMode.once, const Key('reminder-repeat-once')),
        pill(
          'Weekdays',
          ReminderRepeatMode.weekdays,
          const Key('reminder-repeat-weekdays'),
        ),
        pill(
          'Custom',
          ReminderRepeatMode.custom,
          const Key('reminder-repeat-custom'),
        ),
      ],
    );
  }

  Widget _dayPicker() {
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return AleraCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                _DayDot(
                  key: ValueKey('reminder-day-toggle-${i + 1}'),
                  letter: letters[i],
                  selected: _repeat.customDays.contains(i + 1),
                  onTap: () => setState(() {
                    final days = {..._repeat.customDays};
                    if (!days.add(i + 1)) days.remove(i + 1);
                    _repeat = _repeat.copyWith(customDays: days);
                    _customDaysError = false;
                  }),
                ),
            ],
          ),
          if (_customDaysError) ...[
            const SizedBox(height: 8),
            const Text(
              'Pick at least one day.',
              key: Key('reminder-custom-days-error'),
              style: TextStyle(fontSize: 11, color: AleraColors.critical),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dropdownRow<T>({
    required Key fieldKey,
    required String label,
    required T value,
    required List<T> values,
    required String Function(T) text,
    required ValueChanged<T> onChanged,
  }) => _SettingRow(
    label: label,
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        key: fieldKey,
        value: value,
        isDense: true,
        alignment: AlignmentDirectional.centerEnd,
        icon: const Icon(
          Icons.keyboard_arrow_down,
          size: 20,
          color: AleraColors.fieldHint,
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
        style: _valueStyle,
        items: [
          for (final v in values)
            DropdownMenuItem(value: v, child: Text(text(v))),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_repeat.isValid) {
      setState(() => _customDaysError = true);
      return;
    }
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
        scheduleRule: _repeat.rule,
        snoozeAllowed: _snoozeAllowed,
        notificationChannel: _channel,
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.child, this.onTap});

  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AleraColors.textPrimary,
              ),
            ),
          ),
          child,
        ],
      ),
    ),
  );
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: AleraColors.divider);
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    super.key,
    required this.letter,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkResponse(
    onTap: onTap,
    radius: 24,
    child: Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AleraColors.primary : AleraColors.primarySoft,
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AleraColors.textSecondary,
        ),
      ),
    ),
  );
}
