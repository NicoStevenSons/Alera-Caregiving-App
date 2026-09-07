import 'package:alera/features/patient/presentation/patient_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('manual code formatting normalizes paste and inserts hyphens', () {
    expect(normalizePatientAccessCode(' 7k3m 9q2d r8tx '), '7K3M-9Q2D-R8TX');
    expect(normalizePatientAccessCode('7k3m9q'), '7K3M-9Q');
    expect(isValidPatientAccessCode('7K3M-9Q2D-R8TX'), isTrue);

    const formatter = PatientAccessCodeFormatter();
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '7k3m9q2dr8tx'),
    );
    expect(result.text, '7K3M-9Q2D-R8TX');
  });

  test('formatter rejects ambiguous alphabet characters', () {
    expect(
      normalizePatientAccessCode('O0I1L-7K3M-9Q2D-R8TX'),
      '7K3M-9Q2D-R8TX',
    );
  });

  test('valid version-2 patient QR returns normalized code', () {
    final result = parsePatientAccessQr(
      '{"type":"alera_patient_access","version":2,"access_code":"7k3m 9q2d r8tx"}',
    );
    expect(result, isA<ValidPatientQr>());
    expect((result as ValidPatientQr).accessCode, '7K3M-9Q2D-R8TX');
  });

  test('malformed and unrelated QR payloads are rejected', () {
    for (final raw in [
      'not json',
      '[]',
      '{"type":"website","version":2,"access_code":"7K3M-9Q2D-R8TX"}',
      '{"type":"alera_patient_access","version":2,"access_code":"bad"}',
    ]) {
      final result = parsePatientAccessQr(raw);
      expect(result, isA<InvalidPatientQr>());
      expect((result as InvalidPatientQr).message, invalidPatientQrMessage);
    }
  });

  test('version-1 patient QR reports unsupported invitation', () {
    final result = parsePatientAccessQr(
      '{"type":"alera_patient_access","version":1,"access_code":"7K3M-9Q2D-R8TX"}',
    );
    expect((result as InvalidPatientQr).message, unsupportedPatientQrMessage);
  });

  test('scan guard suppresses duplicate detections until reset', () {
    final guard = PatientScanGuard();
    expect(guard.claim(), isTrue);
    expect(guard.claim(), isFalse);
    guard.reset();
    expect(guard.claim(), isTrue);
  });

  test('camera detection boundary parses and suppresses duplicate scans', () {
    var parseCalls = 0;
    final boundary = PatientQrDetectionBoundary(
      parser: (raw) {
        parseCalls++;
        return const ValidPatientQr('7K3M-9Q2D-R8TX');
      },
    );

    expect(boundary.inspect([null, '']), isNull);
    expect(boundary.inspect(['camera-value']), isA<ValidPatientQr>());
    expect(boundary.inspect(['duplicate-value']), isNull);
    expect(parseCalls, 2);
    boundary.allowRetry();
    expect(boundary.inspect(['retry-value']), isA<ValidPatientQr>());
  });
}
