/// The relationship between the signed-in caregiver and one patient
/// ("Mother", "Client", ...).
///
/// This belongs to the caregiver-patient *assignment*, not to the patient: the
/// same person can be one caregiver's mother and another's client. Never store
/// it on a shared patient profile.
const int relationshipLabelMaxLength = 50;

/// Quick picks shown under the field. Custom text is always allowed.
const List<String> relationshipLabelSuggestions = <String>[
  'Mother',
  'Father',
  'Grandmother',
  'Grandfather',
  'Spouse',
  'Relative',
  'Client',
  'Friend',
];

/// Collapses runs of whitespace to single spaces and trims the ends. Returns
/// null for blank input, which means "no relationship set".
String? normalizeRelationshipLabel(String? value) {
  if (value == null) return null;
  final collapsed = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  return collapsed.isEmpty ? null : collapsed;
}

/// Form validator. Blank is valid (the label is optional).
String? validateRelationshipLabel(String? value) {
  final normalized = normalizeRelationshipLabel(value);
  if (normalized != null && normalized.length > relationshipLabelMaxLength) {
    return 'Use $relationshipLabelMaxLength characters or fewer.';
  }
  return null;
}
