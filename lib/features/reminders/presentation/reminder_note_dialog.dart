import 'package:flutter/material.dart';

import '../../../design_system/widgets/alera_dialog.dart';
import '../../../design_system/widgets/alera_text_field.dart';

/// Asks the caregiver for a note before acting on a patient's reminder.
/// Same look as the other Alera dialogs: white rounded dialog, icon circle,
/// centred copy, shared text field, and the pill button pair. Resolves to
/// the trimmed note, or null if dismissed.
Future<String?> showReminderNoteDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String hint,
  required String actionLabel,
}) => showDialog<String>(
  context: context,
  builder: (context) => _ReminderNoteDialog(
    icon: icon,
    title: title,
    hint: hint,
    actionLabel: actionLabel,
  ),
);

class _ReminderNoteDialog extends StatefulWidget {
  const _ReminderNoteDialog({
    required this.icon,
    required this.title,
    required this.hint,
    required this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String hint;
  final String actionLabel;

  @override
  State<_ReminderNoteDialog> createState() => _ReminderNoteDialogState();
}

class _ReminderNoteDialogState extends State<_ReminderNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => AleraDialog(
    icon: widget.icon,
    title: widget.title,
    message: widget.hint,
    confirmLabel: widget.actionLabel,
    onConfirm: _submit,
    content: Form(
      key: _formKey,
      child: AleraTextField(
        fieldKey: const Key('reminder-action-note'),
        controller: _controller,
        label: 'Note',
        hint: 'Write a short note',
        required: true,
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
        bottomSpacing: 0,
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Add a short note.' : null,
      ),
    ),
  );
}
