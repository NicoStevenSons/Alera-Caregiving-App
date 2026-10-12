import 'caregiver_patient_api_data_source.dart';

/// Archives a patient for the signed-in caregiver.
///
/// The production implementation is [CaregiverPatientApiDataSource.archivePatient]
/// (`POST /api/v1/patients/{patient_id}/archive`); the contract is in
/// docs/patient-editing.md. `CaregiverAuthGate` passes it to `CaregiverShell`
/// as `patientArchiveDataSource`.
abstract interface class CaregiverPatientArchiveDataSource {
  /// Archives [patientId]. Throws [CaregiverPatientApiFailure] with a
  /// caregiver-readable message when it cannot.
  Future<void> archivePatient(String patientId);
}

/// Fallback for screens built without an archive data source (previews and
/// tests). Always fails with a clear message so nothing appears archived.
class UnavailablePatientArchiveDataSource
    implements CaregiverPatientArchiveDataSource {
  const UnavailablePatientArchiveDataSource();

  @override
  Future<void> archivePatient(String patientId) => Future<void>.error(
    const CaregiverPatientApiFailure(
      'Archiving patients isn’t available yet. Nothing was changed.',
    ),
  );
}
