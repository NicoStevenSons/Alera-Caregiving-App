import 'package:flutter/material.dart';

import '../../../design_system/alera_colors.dart';
import '../../../design_system/widgets/alera_button.dart';
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
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AleraColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AleraColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(widget.icon, size: 28, color: AleraColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AleraColors.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.hint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AleraColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              AleraTextField(
                fieldKey: const Key('reminder-action-note'),
                controller: _controller,
                label: 'Note',
                hint: 'Write a short note',
                required: true,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                bottomSpacing: 20,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Add a short note.'
                    : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: AleraButton(
                      label: 'Back',
                      variant: AleraButtonVariant.lightPill,
                      height: 44,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AleraButton(
                      label: widget.actionLabel,
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
}
