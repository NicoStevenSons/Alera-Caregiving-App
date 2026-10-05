import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../alera_colors.dart';
import '../alera_typography.dart';

/// Filled lavender input: the one shared text-field look for the whole app
/// (form-field counterpart to [AleraButton] and [AleraCard]). This is the
/// same field the caregiver sign-in flow uses (see `_authTextField` in
/// caregiver_auth_gate.dart, which now delegates here) so every text input -
/// login, Add Patient, patient access - renders identically, including in
/// its disabled/busy state.
class AleraTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final Key? fieldKey;
  final bool required;
  final bool enabled;
  final bool obscureText;
  final bool autocorrect;
  final bool? enableSuggestions;
  final TextCapitalization textCapitalization;
  final String? suffixText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final int maxLines;
  final double bottomSpacing;

  const AleraTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.fieldKey,
    this.required = false,
    this.enabled = true,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions,
    this.textCapitalization = TextCapitalization.none,
    this.suffixText,
    this.suffixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
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
            enabled: enabled,
            obscureText: obscureText,
            autocorrect: autocorrect,
            enableSuggestions: enableSuggestions ?? !obscureText,
            textCapitalization: textCapitalization,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            onChanged: onChanged,
            onFieldSubmitted: onFieldSubmitted,
            minLines: 1,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 13, color: AleraColors.textPrimary),
            cursorColor: AleraColors.primary,
            decoration: aleraInputDecoration(
              hint: hint,
              suffixText: suffixText,
              suffixIcon: suffixIcon,
            ),
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
      style: AleraTypography.label.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Shared filled/bordered decoration so [AleraTextField], the birthdate
/// boxes, the sex dropdown, and the caregiver sign-in fields all render as
/// one family of inputs - this is the exact style the sign-in screen
/// originated (fill/border colours and radius), now the single source both
/// pull from. Declares every border state, including [disabledBorder]:
/// leaving it unset was the bug where a busy/disabled field fell back to
/// Flutter's default underline style instead of keeping its rounded shape.
InputDecoration aleraInputDecoration({
  required String hint,
  String? suffixText,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AleraColors.fieldHint),
    suffixText: suffixText,
    suffixIcon: suffixIcon,
    suffixStyle: const TextStyle(fontSize: 12, color: AleraColors.fieldHint),
    filled: true,
    fillColor: AleraColors.fieldFill,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    errorStyle: const TextStyle(fontSize: 11, color: AleraColors.critical),
    border: border(AleraColors.fieldBorder),
    enabledBorder: border(AleraColors.fieldBorder),
    focusedBorder: border(AleraColors.primary, 1.5),
    errorBorder: border(AleraColors.critical),
    focusedErrorBorder: border(AleraColors.critical, 1.5),
    disabledBorder: border(AleraColors.fieldBorder.withValues(alpha: 0.6)),
  );
}
