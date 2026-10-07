import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alera/features/caregiver/presentation/people/widgets/relationship_field.dart';

import 'package:alera/features/caregiver/data/api/caregiver_patient_api_data_source.dart';
import 'package:alera/features/caregiver/data/api/caregiver_patient_edit_data_source.dart';
import 'package:alera/features/caregiver/data/api/dto/patient_dto.dart';

Map<String, dynamic> editPatientJson({
  String name = 'Maria Santos',
  String? relationship,
  String? photoUrl,
}) => {
  'patient_id': 'patient-1',
  'user_id': 'user-1',
  'household_id': 'household-1',
  'full_name': name,
  'birthdate': '1950-02-03',
  'sex': 'FEMALE',
  'phone_number': '09123456789',
  'address_or_room': 'Room 4',
  'profile_photo_url': photoUrl,
  'account_status': 'ACTIVE',
  'created_at': '2026-09-06T10:00:00Z',
  'relationship_label': relationship,
  'current_summary': {
    'latest_heart_rate': null,
    'latest_spo2': null,
    'last_check_in': null,
    'active_alert_count': 0,
    'highest_active_alert_severity': null,
    'monitoring_status': 'NO_DATA',
    'device_connection_status': 'NOT_CONNECTED',
    'last_device_sync_at': null,
  },
  'emergency_contact_name': 'Juan',
  'emergency_contact_phone': '555-0100',
  'known_conditions': 'Hypertension',
  'medications': 'Medication A',
  'baseline_heart_rate': null,
  'baseline_spo2': null,
  'monitoring_notes': 'Morning checks',
  'archived_at': null,
  'assignment': null,
  'normal_hr_min': 60,
  'normal_hr_max': 100,
  'usual_spo2_min': 95,
  'usual_spo2_max': null,
  'threshold_mode': 'DEFAULT',
  'patient_access': {
    'status': 'NOT_CONNECTED',
    'pending_access_code_id': null,
    'pending_expires_at': null,
    'connected_at': null,
  },
};

PatientDetailDto editPatient({String? relationship}) =>
    PatientDetailDto.fromJson(editPatientJson(relationship: relationship));

/// Echoes the request back as the saved patient, or fails when told to.
class FakePatientEditDataSource implements CaregiverPatientEditDataSource {
  final List<UpdatePatientRequest> requests = [];
  Object? failure;
  Completer<void>? gate;

  @override
  Future<PatientDetailDto> updatePatient(
    String patientId,
    UpdatePatientRequest request,
  ) async {
    requests.add(request);
    await gate?.future;
    final error = failure;
    if (error != null) throw error;
    return PatientDetailDto.fromJson(
      editPatientJson(
        name: request.fullName.trim(),
        relationship: request.relationshipLabel,
      ),
    );
  }
}

class FakePhotoDataSource implements CaregiverPatientDataSource {
  final List<String> uploads = [];
  bool failUpload = false;

  @override
  Future<PatientProfilePhotoResponse> uploadProfilePhoto(
    String patientId, {
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    if (failUpload) throw const CaregiverPatientApiFailure('upload failed');
    uploads.add(filename);
    return PatientProfilePhotoResponse(
      patientId: patientId,
      profilePhotoUrl: 'https://example.com/new.png',
    );
  }

  @override
  Future<PatientCreatedResponse> createPatient(CreatePatientRequest request) =>
      throw UnimplementedError();

  @override
  Future<PatientAccessCodeResponse> createAccessCode(String patientId) =>
      throw UnimplementedError();

  @override
  Future<MonitoringSettingsResponse> updateMonitoringSettings(
    String patientId,
    UpdateMonitoringSettingsRequest request,
  ) => throw UnimplementedError();
}

/// The relationship dropdown (the Sex dropdown is also a
/// DropdownButtonFormField, so scope to the relationship field).
Finder get relationshipDropdown => find.descendant(
  of: find.byType(RelationshipField),
  matching: find.byType(DropdownButtonFormField<String>),
);

/// Opens the relationship dropdown and picks [label] ("Mother", "Other…",
/// "Not set", ...).
Future<void> pickRelationship(WidgetTester tester, String label) async {
  await tester.ensureVisible(relationshipDropdown);
  await tester.tap(relationshipDropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}
