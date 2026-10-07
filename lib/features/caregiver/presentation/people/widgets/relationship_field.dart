import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/widgets/alera_text_field.dart';
import '../../../domain/relationship_label.dart';

/// Optional "how are you related to this person" input shared by Add Patient
/// and Edit Patient.
///
/// One dropdown with the common choices; a text box appears only when the
/// caregiver picks "Other…" (or the saved label isn't one of the choices), so
/// there is never a second control repeating the first. The value is read from
/// and written to [controller], which callers normalize on submit.
class RelationshipField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;

  const RelationshipField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  @override
  State<RelationshipField> createState() => _RelationshipFieldState();
}

class _RelationshipFieldState extends State<RelationshipField> {
  static const String _other = '__other__';
  static const String _none = '__none__';

  late bool _otherMode;

  @override
  void initState() {
    super.initState();
    final current = normalizeRelationshipLabel(widget.controller.text);
    _otherMode = current != null && _suggestionFor(current) == null;
  }

  String? _suggestionFor(String? label) {
    if (label == null) return null;
    for (final suggestion in relationshipLabelSuggestions) {
      if (suggestion.toLowerCase() == label.toLowerCase()) return suggestion;
    }
    return null;
  }

  String? get _selection {
    if (_otherMode) return _other;
    return _suggestionFor(normalizeRelationshipLabel(widget.controller.text));
  }

  void _choose(String? value) {
    setState(() {
      if (value == _other) {
        _otherMode = true;
        // Don't carry a previously picked suggestion into the free-text box.
        if (_suggestionFor(
              normalizeRelationshipLabel(widget.controller.text),
            ) !=
            null) {
          widget.controller.clear();
        }
      } else if (value == null || value == _none) {
        _otherMode = false;
        widget.controller.clear();
      } else {
        _otherMode = false;
        widget.controller.text = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selection = _selection;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: _otherMode ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AleraFieldLabel('Your relationship (optional)'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                // A new key re-reads initialValue when the choice is changed
                // from code (for example clearing it).
                key: ValueKey<String?>(selection),
                initialValue: selection,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: AleraColors.fieldHint,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                style: const TextStyle(
                  fontSize: 13,
                  color: AleraColors.textPrimary,
                ),
                decoration: aleraInputDecoration(hint: 'e.g. Mother, Client'),
                items: [
                  if (selection != null)
                    const DropdownMenuItem(
                      value: _none,
                      child: Text('Not set'),
                    ),
                  for (final suggestion in relationshipLabelSuggestions)
                    DropdownMenuItem(
                      value: suggestion,
                      child: Text(suggestion),
                    ),
                  const DropdownMenuItem(value: _other, child: Text('Other…')),
                ],
                onChanged: widget.enabled ? _choose : null,
              ),
            ],
          ),
        ),
        if (_otherMode)
          AleraTextField(
            controller: widget.controller,
            label: 'Describe your relationship',
            hint: 'e.g. Neighbour',
            fieldKey: const Key('relationship-other-field'),
            enabled: widget.enabled,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [
              LengthLimitingTextInputFormatter(relationshipLabelMaxLength),
            ],
            validator: validateRelationshipLabel,
          ),
      ],
    );
  }
}
