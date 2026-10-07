import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/widgets/alera_text_field.dart';
import '../../../domain/relationship_label.dart';

/// Optional "how are you related to this person" input shared by Add Patient
/// and Edit Patient. Free text, with one-tap suggestions underneath.
class RelationshipField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const RelationshipField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AleraTextField(
          controller: controller,
          label: 'Your relationship (optional)',
          hint: 'e.g. Mother, Client',
          fieldKey: const Key('relationship-field'),
          enabled: enabled,
          bottomSpacing: 8,
          textCapitalization: TextCapitalization.sentences,
          inputFormatters: [
            LengthLimitingTextInputFormatter(relationshipLabelMaxLength),
          ],
          validator: validateRelationshipLabel,
          onChanged: onChanged,
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final current = normalizeRelationshipLabel(value.text);
            return Wrap(
              spacing: 8,
              runSpacing: 0,
              children: [
                for (final suggestion in relationshipLabelSuggestions)
                  ChoiceChip(
                    key: Key('relationship-suggestion-$suggestion'),
                    label: Text(suggestion),
                    selected: current?.toLowerCase() == suggestion.toLowerCase(),
                    showCheckmark: false,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    selectedColor: AleraColors.primarySoft,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AleraColors.divider),
                    onSelected: enabled
                        ? (_) {
                            controller.text = suggestion;
                            controller.selection = TextSelection.collapsed(
                              offset: suggestion.length,
                            );
                            onChanged?.call(suggestion);
                          }
                        : null,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
