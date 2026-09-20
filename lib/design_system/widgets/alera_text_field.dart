import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../alera_colors.dart';

/// Filled lavender input: the form-field counterpart to [AleraButton] and
/// [AleraCard]. Introduced for the Add Patient flow's field-heavy steps, but
/// generic (label/hint/validator only) so any other form can adopt it.
class AleraTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final Key? fieldKey;
  final bool required;
  final String? suffixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;
  final double bottomSpacing;

  const AleraTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.fieldKey,
    this.required = false,
    this.suffixText,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
    this.bottomSpacing = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AleraFieldLabel(label, required: required),
          const SizedBox(height: 6),
          TextFormField(
            key: fieldKey,
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            minLines: 1,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 13, color: AleraColors.textPrimary),
            cursorColor: AleraColors.primary,
            decoration: aleraInputDecoration(hint: hint, suffixText: suffixText),
          ),
        ],
      ),
    );
  }
}

/// Field label used above an [AleraTextField] (or any bespoke input that
/// wants to match it, such as the birthdate boxes and the sex dropdown).
class AleraFieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  const AleraFieldLabel(this.text, {super.key, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AleraColors.critical),
            ),
        ],
      ),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AleraColors.textSecondary,
      ),
    );
  }
}

/// Shared filled/bordered decoration so [AleraTextField], the birthdate boxes
/// and the sex dropdown all render as one family of inputs.
InputDecoration aleraInputDecoration({required String hint, String? suffixText}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: AleraColors.fieldHint),
    suffixText: suffixText,
    suffixStyle: const TextStyle(fontSize: 12, color: AleraColors.fieldHint),
    filled: true,
    fillColor: AleraColors.surfaceTint,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    errorStyle: const TextStyle(fontSize: 11, color: AleraColors.critical),
    enabledBorder: border(AleraColors.divider),
    focusedBorder: border(AleraColors.primary.withValues(alpha: 0.55), 1.5),
    errorBorder: border(AleraColors.critical.withValues(alpha: 0.7)),
    focusedErrorBorder: border(AleraColors.critical, 1.5),
    border: border(AleraColors.divider),
  );
}
