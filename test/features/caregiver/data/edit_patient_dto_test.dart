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
}
