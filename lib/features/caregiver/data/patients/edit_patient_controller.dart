
import 'package:flutter/foundation.dart';

import '../api/caregiver_patient_api_data_source.dart';
import '../api/caregiver_patient_edit_data_source.dart';
import '../api/dto/patient_dto.dart';

/// A photo the caregiver picked while editing, ready to upload.
class PatientPhotoUpload {
  final Uint8List bytes;
  final String filename;
  final String contentType;

  const PatientPhotoUpload({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });
}

enum EditPatientStatus { idle, saving, saved, failed }

/// What a successful save produced.
class EditPatientResult {
  final PatientDetailDto patient;

  /// True when the profile saved but the new photo could not be uploaded.
  final bool photoFailed;

  const EditPatientResult({required this.patient, this.photoFailed = false});
}

/// Saves an edited patient profile (and optional photo) and exposes the
/// loading / error state to the form. It never clears the form: the page owns
/// the draft, so a failed save keeps everything the caregiver typed.
class EditPatientController extends ChangeNotifier {
  final String patientId;
  final CaregiverPatientEditDataSource editDataSource;
  final CaregiverPatientDataSource photoDataSource;

  EditPatientStatus status = EditPatientStatus.idle;
  String? errorMessage;
  EditPatientResult? result;
  bool _disposed = false;

  EditPatientController({
    required this.patientId,
    required this.editDataSource,
    required this.photoDataSource,
  });

  bool get isSaving => status == EditPatientStatus.saving;

  /// Returns true when the profile was saved. On false, [errorMessage] says why
  /// and calling [save] again retries.
  Future<bool> save(
    UpdatePatientRequest request, {
    PatientPhotoUpload? photo,
  }) async {
    if (isSaving) return false;
    status = EditPatientStatus.saving;
    errorMessage = null;
    _notify();

    final PatientDetailDto saved;
    try {
      saved = await editDataSource.updatePatient(patientId, request);
    } on CaregiverPatientApiFailure catch (failure) {
      return _fail(failure.message);
    } catch (_) {
      return _fail('Unable to save changes. Please try again.');
    }

    var photoFailed = false;
    var patient = saved;
    if (photo != null) {
      try {
        final uploaded = await photoDataSource.uploadProfilePhoto(
          patientId,
          bytes: photo.bytes,
          filename: photo.filename,
          contentType: photo.contentType,
        );
        patient = saved.withProfilePhotoUrl(uploaded.profilePhotoUrl);
      } catch (_) {
        photoFailed = true;
      }
    }

    result = EditPatientResult(patient: patient, photoFailed: photoFailed);
    status = EditPatientStatus.saved;
    _notify();
    return true;
  }

  bool _fail(String message) {
    status = EditPatientStatus.failed;
    errorMessage = message;
    _notify();
    return false;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
