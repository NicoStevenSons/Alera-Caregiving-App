import 'caregiver_patient_api_data_source.dart';

/// Archives a patient for the signed-in caregiver.
///
/// There is no archive endpoint in the app's API client yet and none is
/// invented here. Edit Patient goes through this interface so the UI, the
/// confirmation and the list/detail updates are ready; once the backend
/// contract is confirmed (see docs/patient-editing.md), add an API data
/// source that implements it and pass it as `patientArchiveDataSource` to
/// `CaregiverShell` in `caregiver_auth_gate.dart`.
abstract interface class CaregiverPatientArchiveDataSource {
  /// Archives [patientId]. Throws [CaregiverPatientApiFailure] with a
  /// caregiver-readable message when it cannot.
  Future<void> archivePatient(String patientId);
}

/// Default until the backend archive endpoint is wired. Always fails with a
/// clear message so nothing appears to have been archived.
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
