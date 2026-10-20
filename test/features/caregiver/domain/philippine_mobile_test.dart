import 'package:alera/features/caregiver/domain/philippine_mobile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizePhilippineMobile', () {
    test('accepts the three formats and returns +639XXXXXXXXX', () {
      expect(normalizePhilippineMobile('09171234567'), '+639171234567');
      expect(normalizePhilippineMobile('639171234567'), '+639171234567');
      expect(normalizePhilippineMobile('+639171234567'), '+639171234567');
    });

    test('ignores spaces, dashes and brackets', () {
      expect(normalizePhilippineMobile(' 0917 123-4567 '), '+639171234567');
      expect(normalizePhilippineMobile('+63 (917) 123 4567'), '+639171234567');
      expect(normalizePhilippineMobile('+639 17-123-4567'), '+639171234567');
    });

    test('rejects everything else', () {
      for (final bad in [
        null,
        '',
        '0917123456', // too short
        '091712345678', // too long
        '08171234567', // not a 09 mobile
        '+63917123456', // missing digit
        '+649171234567',
        '+1 202 555 0100',
        'abcdefghijk',
      ]) {
        expect(normalizePhilippineMobile(bad), isNull, reason: '$bad');
      }
    });
  });

  group('validators', () {
    test('both empty is valid', () {
      expect(validateBackupName('', phoneEntered: false), isNull);
      expect(validateBackupPhone('  ', nameEntered: false), isNull);
    });

    test('either one entered makes the other required', () {
      expect(validateBackupName('', phoneEntered: true), isNotNull);
      expect(validateBackupPhone('', nameEntered: true), isNotNull);
    });

    test('name length and phone format are checked', () {
      expect(validateBackupName('a' * 151, phoneEntered: true), isNotNull);
      expect(validateBackupName('Ana', phoneEntered: true), isNull);
      expect(validateBackupPhone('12345', nameEntered: true), isNotNull);
      expect(validateBackupPhone('09171234567', nameEntered: true), isNull);
    });
  });
}
