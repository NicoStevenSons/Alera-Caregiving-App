import 'package:flutter/material.dart';

import 'alera_button.dart';
import 'alera_dialog.dart';

Future<String?> showAleraTextInputDialog({
  required BuildContext context,
  required String title,
  required String fieldLabel,
  required String submitLabel,
  String cancelLabel = 'Cancel',
  String? initialValue,
  bool requiredInput = true,
  int maxLines = 3,
  Key? fieldKey,
}) => showDialog<String>(
  context: context,
  builder: (_) => _AleraTextInputDialog(
    title: title,
    fieldLabel: fieldLabel,
    submitLabel: submitLabel,
    cancelLabel: cancelLabel,
    initialValue: initialValue,
    requiredInput: requiredInput,
    maxLines: maxLines,
    fieldKey: fieldKey,
  ),
);

Future<void> showAleraAsyncTextInputDialog({
  required BuildContext context,
  required String title,
  required String fieldLabel,
  required String submitLabel,
  required Future<void> Function(String? value) onSubmit,
  String cancelLabel = 'Cancel',
  String? initialValue,
  bool requiredInput = true,
  int maxLines = 3,
  Key? fieldKey,
  String failureMessage = 'We couldn’t save your changes. Please try again.',
}) => showDialog<void>(
  context: context,
  builder: (_) => _AleraTextInputDialog(
    title: title,
    fieldLabel: fieldLabel,
    submitLabel: submitLabel,
    cancelLabel: cancelLabel,
    initialValue: initialValue,
    requiredInput: requiredInput,
    maxLines: maxLines,
    fieldKey: fieldKey,
    onSubmit: onSubmit,
    failureMessage: failureMessage,
  ),
);

class _AleraTextInputDialog extends StatefulWidget {
  const _AleraTextInputDialog({
    required this.title,
    required this.fieldLabel,
    required this.submitLabel,
    required this.cancelLabel,
    required this.requiredInput,
    required this.maxLines,
    this.initialValue,
    this.fieldKey,
    this.onSubmit,
    this.failureMessage,
  });

  final String title;
  final String fieldLabel;
  final String submitLabel;
  final String cancelLabel;
  final String? initialValue;
  final bool requiredInput;
  final int maxLines;
  final Key? fieldKey;
  final Future<void> Function(String? value)? onSubmit;
  final String? failureMessage;

  @override
  State<_AleraTextInputDialog> createState() =>
      _AleraTextInputDialogState();
}

class _AleraTextInputDialogState extends State<_AleraTextInputDialog> {
  late final TextEditingController _controller;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AleraDialog(
    title: widget.title,
    content: TextField(
      key: widget.fieldKey,
      controller: _controller,
      enabled: !_submitting,
      autofocus: true,
      maxLines: widget.maxLines,
      textInputAction: widget.maxLines == 1
          ? TextInputAction.done
          : TextInputAction.newline,
      decoration: InputDecoration(
        labelText: widget.fieldLabel,
        errorText: _error,
      ),
      onSubmitted: widget.maxLines == 1 ? (_) => _submit() : null,
    ),
    actions: [
      TextButton(
        onPressed: _submitting ? null : () => Navigator.pop(context),
        child: Text(widget.cancelLabel),
      ),
      AleraButton(
        label: _submitting ? 'Saving…' : widget.submitLabel,
        onPressed: _submitting ? null : _submit,
        expand: false,
      ),
    ],
  );

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (widget.requiredInput && text.isEmpty) {
      setState(() => _error = '${widget.fieldLabel} is required.');
      return;
    }

    final submit = widget.onSubmit;
    if (submit == null) {
      Navigator.pop(context, text.isEmpty ? null : text);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await submit(text.isEmpty ? null : text);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = widget.failureMessage;
      });
    }
  }
}
