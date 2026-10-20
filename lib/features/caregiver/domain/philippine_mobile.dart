/// Philippine mobile numbers for the backup caregiver's SMS contact.
///
/// Accepted: `09XXXXXXXXX`, `639XXXXXXXXX`, `+639XXXXXXXXX` (spaces, dashes
/// and brackets are ignored). Always sent to the backend as `+639XXXXXXXXX`.
final RegExp _mobile = RegExp(r'^(?:\+639|639|09)(\d{9})$');

/// The number as `+639XXXXXXXXX`, or null when it is not a valid Philippine
/// mobile number.
String? normalizePhilippineMobile(String? raw) {
  if (raw == null) return null;
  final cleaned = raw.replaceAll(RegExp(r'[\s\-()]'), '');
  final match = _mobile.firstMatch(cleaned);
  return match == null ? null : '+639${match.group(1)}';
}

const int kBackupNameMaxLength = 150;

String? validateBackupName(String? value, {required bool phoneEntered}) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) {
    return phoneEntered ? 'Enter the backup caregiver’s name.' : null;
  }
  if (name.length > kBackupNameMaxLength) {
    return 'Use $kBackupNameMaxLength characters or fewer.';
  }
  return null;
}

String? validateBackupPhone(String? value, {required bool nameEntered}) {
  final phone = value?.trim() ?? '';
  if (phone.isEmpty) {
    return nameEntered ? 'Enter the backup caregiver’s mobile number.' : null;
  }
  return normalizePhilippineMobile(phone) == null
      ? 'Enter a Philippine mobile number, e.g. 09171234567.'
      : null;
}
