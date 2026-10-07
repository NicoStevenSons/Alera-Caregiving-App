import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/widgets/alera_svg_icon.dart';
import '../../../../../design_system/widgets/alera_text_field.dart';
import '../../../domain/relationship_label.dart';

const String _iconDir = 'alera-figma-assets/assets/icons/relationships';

/// Icon file for a relationship choice. Every file is currently a copy of
/// status/error.svg; replace the SVGs to change the artwork (see
/// alera-figma-assets/PLACEHOLDER_ICONS.md).
String relationshipIconAsset(String label) =>
    '$_iconDir/${label.toLowerCase()}.svg';

/// Optional "how are you related to this person" input shared by Add Patient
/// and Edit Patient: tap-to-select icon tiles, three per row, like the
/// reminder categories. Tapping the selected tile again clears it. "Other"
/// reveals a text box for a custom label.
///
/// The value is read from and written to [controller], which callers
/// normalize on submit.
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

  String? get _selectedSuggestion => _otherMode
      ? null
      : _suggestionFor(normalizeRelationshipLabel(widget.controller.text));

  void _tapSuggestion(String suggestion) {
    setState(() {
      _otherMode = false;
      if (_selectedSuggestion == suggestion) {
        widget.controller.clear();
      } else {
        widget.controller.text = suggestion;
      }
    });
  }

  void _tapOther() {
    setState(() {
      if (_otherMode) {
        _otherMode = false;
        widget.controller.clear();
      } else {
        _otherMode = true;
        // Don't carry a picked suggestion into the free-text box.
        if (_suggestionFor(normalizeRelationshipLabel(widget.controller.text)) !=
            null) {
          widget.controller.clear();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedSuggestion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AleraFieldLabel('Your relationship (optional)'),
        const SizedBox(height: 8),
        GridView(
          key: const Key('relationship-grid'),
          // Fixed tile height (not an aspect ratio) so every tile has the
          // same top and bottom padding around its icon and label.
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 80,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final suggestion in relationshipLabelSuggestions)
              RelationshipTile(
                key: Key('relationship-$suggestion'),
                label: suggestion,
                iconAsset: relationshipIconAsset(suggestion),
                selected: selected == suggestion,
                onTap: widget.enabled ? () => _tapSuggestion(suggestion) : null,
              ),
            RelationshipTile(
              key: const Key('relationship-Other'),
              label: 'Other',
              iconAsset: relationshipIconAsset('other'),
              selected: _otherMode,
              onTap: widget.enabled ? _tapOther : null,
            ),
          ],
        ),
        SizedBox(height: _otherMode ? 12 : 20),
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

/// One selectable tile: icon above a short label. Same look as the reminder
/// category tiles.
class RelationshipTile extends StatelessWidget {
  final String label;
  final String iconAsset;
  final bool selected;
  final VoidCallback? onTap;

  const RelationshipTile({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected
            ? AleraColors.selected.withValues(alpha: 0.14)
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? AleraColors.selected : AleraColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AleraSvgIcon(assetPath: iconAsset, width: 28, height: 28),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? AleraColors.textPrimary
                        : AleraColors.textSecondary,
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
