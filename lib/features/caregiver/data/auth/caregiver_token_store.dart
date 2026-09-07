import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum SessionType { caregiver, elderlyPatient }

class StoredSession {
  final String token;
  final SessionType type;
  final String? householdCode;
  const StoredSession(this.token, this.type, {this.householdCode});
}

abstract interface class CaregiverTokenStore {
  Future<StoredSession?> readSession();
  Future<void> writeSession(StoredSession session);
  Future<void> clearSession();
}

class SecureCaregiverTokenStore implements CaregiverTokenStore {
  static const String _sessionKey = 'alera_session';
  static const String _legacyTokenKey = 'caregiver_access_token';
  final FlutterSecureStorage _storage;

  SecureCaregiverTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<StoredSession?> readSession() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null) {
      // Previous app versions only persisted caregiver tokens.
      final legacy = await _storage.read(key: _legacyTokenKey);
      if (legacy == null || legacy.trim().isEmpty) {
        await clearSession();
        return null;
      }
      final session = StoredSession(legacy, SessionType.caregiver);
      await writeSession(session);
      return session;
    }
    try {
      final value = jsonDecode(raw);
      if (value is! Map<String, dynamic>) throw const FormatException();
      final token = value['token'];
      final type = switch (value['type']) {
        'caregiver' => SessionType.caregiver,
        'elderly_patient' => SessionType.elderlyPatient,
        _ => null,
      };
      if (token is! String || token.trim().isEmpty || type == null) {
        throw const FormatException();
      }
      final householdCode = value['household_code'];
      return StoredSession(
        token,
        type,
        householdCode: householdCode is String && householdCode.isNotEmpty
            ? householdCode
            : null,
      );
    } on FormatException {
      await clearSession();
      return null;
    }
  }

  @override
  Future<void> writeSession(StoredSession session) async {
    // A single secure value prevents token/type mismatches on interrupted writes.
    await _storage.write(
      key: _sessionKey,
      value: jsonEncode({
        'token': session.token,
        'type': session.type == SessionType.caregiver
            ? 'caregiver'
            : 'elderly_patient',
        if (session.householdCode != null)
          'household_code': session.householdCode,
      }),
    );
    await _storage.delete(key: _legacyTokenKey);
  }

  @override
  Future<void> clearSession() async {
    try {
      await _storage.delete(key: _sessionKey);
    } finally {
      await _storage.delete(key: _legacyTokenKey);
    }
  }
}
