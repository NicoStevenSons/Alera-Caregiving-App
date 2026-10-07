import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/patients/edit_patient_controller.dart';

/// Thrown with a message that is safe to show the caregiver.
class PatientPhotoException implements Exception {
  final String message;
  const PatientPhotoException(this.message);
}

typedef PatientPhotoPickerFn = Future<PatientPhotoUpload?> Function();

const int _maxPhotoBytes = 5 * 1024 * 1024;
const Set<String> _allowedTypes = {'image/jpeg', 'image/png', 'image/webp'};

/// Gallery pick + square crop, with the same limits Add Patient enforces
/// (JPEG / PNG / WebP, 5 MB). Returns null when the caregiver backs out.
Future<PatientPhotoUpload?> pickAndCropPatientPhoto() async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 90,
  );
  if (picked == null) return null;

  final cropped = await ImageCropper().cropImage(
    sourcePath: picked.path,
    compressQuality: 90,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Crop photo',
        toolbarColor: const Color(0xFFF9F5FF),
        toolbarWidgetColor: const Color(0xFF3F365C),
        backgroundColor: const Color(0xFFF5F0FA),
        dimmedLayerColor: const Color(0x99000000),
        activeControlsWidgetColor: const Color(0xFFA884E8),
        lockAspectRatio: true,
        showCropGrid: true,
        hideBottomControls: false,
        aspectRatioPresets: [CropAspectRatioPreset.square],
      ),
      IOSUiSettings(
        title: 'Crop photo',
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPresets: const [CropAspectRatioPreset.square],
      ),
    ],
  );
  if (cropped == null) return null;

  final file = XFile(cropped.path);
  final bytes = await file.readAsBytes();
  final contentType = _mimeType(file);
  if (contentType == null || !_allowedTypes.contains(contentType)) {
    throw const PatientPhotoException('Choose a JPEG, PNG, or WebP image.');
  }
  if (bytes.length > _maxPhotoBytes) {
    throw const PatientPhotoException(
      'Choose a photo that is 5 MB or smaller.',
    );
  }
  return PatientPhotoUpload(
    bytes: bytes,
    filename: file.name,
    contentType: contentType,
  );
}

String? _mimeType(XFile file) {
  final mime = file.mimeType?.toLowerCase();
  if (mime != null && _allowedTypes.contains(mime)) return mime;
  final lower = file.name.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return null;
}
