import 'package:alera/features/caregiver/data/api/dto/patient_dto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../people/edit_patient_test_support.dart';

void main() {
  test('update request sends every editable field and clears blanks', () {
    final json = UpdatePatientRequest(
      fullName: ' Maria Santos ',
      birthdate: DateTime(1950, 2, 3),
      sex: 'FEMALE',
      phoneNumber: ' 0912 ',
      addressOrRoom: '   ',
      emergencyContactName: 'Juan',
      emergencyContactPhone: '',
      knownConditions: 'Hypertension',
      medications: null,
      monitoringNotes: 'Notes',
      relationshipLabel: '  Grand   mother ',
    ).toJson();

    expect(json, {
      'full_name': 'Maria Santos',
      'birthdate': '1950-02-03',
      'sex': 'FEMALE',
      'phone_number': '0912',
      'address_or_room': null,
      'emergency_contact_name': 'Juan',
      'emergency_contact_phone': null,
      'known_conditions': 'Hypertension',
      'medications': null,
      'monitoring_notes': 'Notes',
      'backup_caregiver_name': null,
      'backup_caregiver_phone': null,
      'relationship_label': 'Grand mother',
    });
    // Thresholds and baselines are not part of the general edit form.
    expect(json.keys, isNot(contains('normal_hr_min')));
    expect(json.keys, isNot(contains('baseline_heart_rate')));
  });

  test('create request only sends a relationship when one is set', () {
    expect(
      const CreatePatientRequest(fullName: 'Ada').toJson(),
      isNot(contains('relationship_label')),
    );
    expect(
      const CreatePatientRequest(
        fullName: 'Ada',
        relationshipLabel: '   ',
      ).toJson(),
      isNot(contains('relationship_label')),
    );
    expect(
      const CreatePatientRequest(
        fullName: 'Ada',
        relationshipLabel: ' Client ',
      ).toJson()['relationship_label'],
      'Client',
    );
  });

  test('patient DTOs read the per-caregiver relationship label', () {
    expect(editPatient(relationship: 'Mother').relationshipLabel, 'Mother');
    expect(editPatient().relationshipLabel, isNull);
    final padded = PatientDetailDto.fromJson(
      editPatientJson(relationship: '  Client  '),
    );
    expect(padded.relationshipLabel, 'Client');
  });

  group('backup caregiver contact', () {
    test('update request normalises the phone and sends both fields', () {
      final json = const UpdatePatientRequest(
        fullName: 'Maria',
        backupCaregiverName: ' Ana Cruz ',
        backupCaregiverPhone: '0917 123-4567',
      ).toJson();
      expect(json['backup_caregiver_name'], 'Ana Cruz');
      expect(json['backup_caregiver_phone'], '+639171234567');
    });

    test('update request sends explicit nulls to remove the contact', () {
      final json = const UpdatePatientRequest(
        fullName: 'Maria',
        backupCaregiverName: '  ',
        backupCaregiverPhone: '',
      ).toJson();
      expect(json.containsKey('backup_caregiver_name'), isTrue);
      expect(json.containsKey('backup_caregiver_phone'), isTrue);
      expect(json['backup_caregiver_name'], isNull);
      expect(json['backup_caregiver_phone'], isNull);
    });

    test('create request only sends a backup contact when set', () {
      final none = const CreatePatientRequest(fullName: 'Ada').toJson();
      expect(none, isNot(contains('backup_caregiver_name')));
      expect(none, isNot(contains('backup_caregiver_phone')));

      final set = const CreatePatientRequest(
        fullName: 'Ada',
        backupCaregiverName: 'Ana',
        backupCaregiverPhone: '639171234567',
      ).toJson();
      expect(set['backup_caregiver_name'], 'Ana');
      expect(set['backup_caregiver_phone'], '+639171234567');
    });

    test('patient detail parses the backup fields, or null when absent', () {
      final withBackup = PatientDetailDto.fromJson({
        ...editPatientJson(),
        'backup_caregiver_name': 'Ana Cruz',
        'backup_caregiver_phone': '+639171234567',
      });
      expect(withBackup.backupCaregiverName, 'Ana Cruz');
      expect(withBackup.backupCaregiverPhone, '+639171234567');

      final without = PatientDetailDto.fromJson(editPatientJson());
      expect(without.backupCaregiverName, isNull);
      expect(without.backupCaregiverPhone, isNull);
    });

    test('created response parses the backup fields', () {
      final json = {
        'patient_id': 'p',
        'user_id': 'u',
        'household_id': 'h',
        'account_status': 'ACTIVE',
        'assignment': null,
        'full_name': 'Ada',
        'created_at': '2026-10-01T00:00:00Z',
        'backup_caregiver_name': 'Ana',
        'backup_caregiver_phone': '+639171234567',
      };
      final r = PatientCreatedResponse.fromJson(json);
      expect(r.backupCaregiverName, 'Ana');
      expect(r.backupCaregiverPhone, '+639171234567');
    });
  });
}
