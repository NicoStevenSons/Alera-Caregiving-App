import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Decodes identity only for a local preference key.
/// This does not validate a JWT or grant access to patient data.
String? caregiverSelectionScope(String? accessToken) {
  if (accessToken == null) return null;

  try {
    final parts = accessToken.split('.');
    if (parts.length != 3) return null;

    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (payload is! Map<String, dynamic>) return null;

    final subject = payload['sub'];
    if (subject is! String) return null;

    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuid.hasMatch(subject) ? subject.toLowerCase() : null;
  } on FormatException {
    return null;
  }
}

abstract interface class CaregiverPatientSelectionStore {
  Future<String?> read(String caregiverId);
  Future<void> write(String caregiverId, String patientId);
  Future<void> clear(String caregiverId);
}

class SecureCaregiverPatientSelectionStore
    implements CaregiverPatientSelectionStore {
  SecureCaregiverPatientSelectionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _key(String caregiverId) => 'alera_selected_patient_v1_$caregiverId';

  @override
  Future<String?> read(String caregiverId) async {
    final value = await _storage.read(key: _key(caregiverId));
    return value == null || value.trim().isEmpty ? null : value;
  }

  @override
  Future<void> write(String caregiverId, String patientId) =>
      _storage.write(key: _key(caregiverId), value: patientId);

  @override
  Future<void> clear(String caregiverId) =>
      _storage.delete(key: _key(caregiverId));
}
