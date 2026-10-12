import 'caregiver_patient_api_data_source.dart';
import 'dto/patient_dto.dart';

/// Updates an existing patient's profile for the signed-in caregiver.
///
/// The production implementation is [CaregiverPatientApiDataSource.updatePatient]
/// (`PATCH /api/v1/patients/{patient_id}`); the contract is documented in
/// docs/patient-editing.md. [UnavailablePatientEditDataSource] remains as the
/// safe fallback for screens built without a data source (previews, tests).
abstract interface class CaregiverPatientEditDataSource {
  /// Saves [request] for [patientId] and returns the refreshed patient.
  Future<PatientDetailDto> updatePatient(
    String patientId,
    UpdatePatientRequest request,
  );
}

/// Fallback for screens built without an edit data source. Always fails with
/// a clear, retryable-looking message so the edit form keeps the user's draft.
class UnavailablePatientEditDataSource
    implements CaregiverPatientEditDataSource {
  const UnavailablePatientEditDataSource();

  @override
  Future<PatientDetailDto> updatePatient(
    String patientId,
    UpdatePatientRequest request,
  ) {
    return Future<PatientDetailDto>.error(
      const CaregiverPatientApiFailure(
        'Editing patient details isn’t available yet. Your changes are '
        'still here.',
      ),
    );
  }
}
