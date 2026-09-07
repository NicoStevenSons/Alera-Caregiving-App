import 'dart:convert';

import 'package:flutter/services.dart';

const patientAccessAlphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
const invalidPatientQrMessage = 'This isn’t a valid Alera patient QR code.';
const unsupportedPatientQrMessage =
    'This invitation isn’t supported by this version of Alera.';

String normalizePatientAccessCode(String value) {
  final allowed = patientAccessAlphabet.split('').toSet();
  final compact = value
      .toUpperCase()
      .split('')
      .where((character) => allowed.contains(character))
      .take(12)
      .join();
  return [
    for (var offset = 0; offset < compact.length; offset += 4)
      compact.substring(offset, (offset + 4).clamp(0, compact.length)),
  ].join('-');
}

bool isValidPatientAccessCode(String value) => RegExp(
  r'^[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{4}(?:-[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{4}){2}$',
).hasMatch(value);

class PatientAccessCodeFormatter extends TextInputFormatter {
  const PatientAccessCodeFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = normalizePatientAccessCode(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

sealed class PatientQrParseResult {
  const PatientQrParseResult();
}

class ValidPatientQr extends PatientQrParseResult {
  final String accessCode;
  const ValidPatientQr(this.accessCode);
}

class InvalidPatientQr extends PatientQrParseResult {
  final String message;
  const InvalidPatientQr(this.message);
}

PatientQrParseResult parsePatientAccessQr(String raw) {
  try {
    final value = jsonDecode(raw);
    if (value is! Map<String, dynamic> ||
        value['type'] != 'alera_patient_access') {
      return const InvalidPatientQr(invalidPatientQrMessage);
    }
    if (value['version'] != 2) {
      return const InvalidPatientQr(unsupportedPatientQrMessage);
    }
    final code = value['access_code'];
    if (code is! String) {
      return const InvalidPatientQr(invalidPatientQrMessage);
    }
    final normalized = normalizePatientAccessCode(code);
    return isValidPatientAccessCode(normalized)
        ? ValidPatientQr(normalized)
        : const InvalidPatientQr(invalidPatientQrMessage);
  } catch (_) {
    return const InvalidPatientQr(invalidPatientQrMessage);
  }
}

class PatientScanGuard {
  bool _claimed = false;
  bool get claimed => _claimed;
  bool claim() {
    if (_claimed) return false;
    _claimed = true;
    return true;
  }

  void reset() => _claimed = false;
}

typedef PatientQrParser = PatientQrParseResult Function(String raw);

/// Boundary between camera detections and QR parsing/authentication.
///
/// It accepts the raw values emitted by a camera capture, ignores unusable
/// values, and lets only the first valid invitation proceed.
class PatientQrDetectionBoundary {
  final PatientQrParser parser;
  final PatientScanGuard _guard;

  PatientQrDetectionBoundary({
    this.parser = parsePatientAccessQr,
    PatientScanGuard? guard,
  }) : _guard = guard ?? PatientScanGuard();

  PatientQrParseResult? inspect(Iterable<String?> rawValues) {
    final raw = rawValues
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .firstOrNull;
    if (raw == null) return null;
    final result = parser(raw);
    if (result is ValidPatientQr && !_guard.claim()) return null;
    return result;
  }

  void allowRetry() => _guard.reset();
}
