import 'caregiver_patient_api_data_source.dart';
import 'dto/patient_dto.dart';

/// Updates an existing patient's profile for the signed-in caregiver.
///
/// The backend contract is documented in docs/patient-editing.md. Until that
/// endpoint exists the app uses [UnavailablePatientEditDataSource], so no URL
/// is guessed or hardcoded here.
abstract interface class CaregiverPatientEditDataSource {
  /// Saves [request] for [patientId] and returns the refreshed patient.
  Future<PatientDetailDto> updatePatient(
    String patientId,
    UpdatePatientRequest request,
  );
}

/// Default until the backend update endpoint exists. Always fails with a
/// clear, retryable-looking message so the edit form keeps the user's draft.
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
