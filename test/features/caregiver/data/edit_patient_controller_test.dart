import 'dart:async';
import 'dart:typed_data';

import 'package:alera/features/caregiver/data/api/caregiver_patient_api_data_source.dart';
import 'package:alera/features/caregiver/data/api/caregiver_patient_edit_data_source.dart';
import 'package:alera/features/caregiver/data/api/dto/monitoring_device_dto.dart';
import 'package:alera/features/caregiver/data/api/dto/patient_dto.dart';
import 'package:alera/features/caregiver/data/patients/caregiver_patient_controller.dart';
import 'package:alera/features/caregiver/data/patients/edit_patient_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../people/edit_patient_test_support.dart';

EditPatientController _controller(
  FakePatientEditDataSource edit,
  FakePhotoDataSource photos,
) => EditPatientController(
  patientId: 'patient-1',
  editDataSource: edit,
  photoDataSource: photos,
);

void main() {
  test('saves, reports saving, and exposes the refreshed patient', () async {
    final edit = FakePatientEditDataSource()..gate = Completer<void>();
    final controller = _controller(edit, FakePhotoDataSource());
    addTearDown(controller.dispose);

    final future = controller.save(
      const UpdatePatientRequest(
        fullName: 'Maria',
        relationshipLabel: 'Mother',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.status, EditPatientStatus.saving);
    // A second tap while saving is ignored.
    expect(
      await controller.save(const UpdatePatientRequest(fullName: 'x')),
      false,
    );
    expect(edit.requests, hasLength(1));

    edit.gate!.complete();
    expect(await future, isTrue);
    expect(controller.status, EditPatientStatus.saved);
    expect(controller.result!.patient.relationshipLabel, 'Mother');
    expect(controller.result!.photoFailed, isFalse);
  });

  test('a failed save reports the message and can be retried', () async {
    final edit = FakePatientEditDataSource()
      ..failure = const CaregiverPatientApiFailure('Server is busy.');
    final controller = _controller(edit, FakePhotoDataSource());
    addTearDown(controller.dispose);

    expect(
      await controller.save(const UpdatePatientRequest(fullName: 'Maria')),
      isFalse,
    );
    expect(controller.status, EditPatientStatus.failed);
    expect(controller.errorMessage, 'Server is busy.');
    expect(controller.result, isNull);

    edit.failure = null;
    expect(
      await controller.save(const UpdatePatientRequest(fullName: 'Maria')),
      isTrue,
    );
    expect(controller.errorMessage, isNull);
    expect(controller.status, EditPatientStatus.saved);
  });

  test('unexpected errors become a generic retryable message', () async {
    final edit = FakePatientEditDataSource()..failure = StateError('boom');
    final controller = _controller(edit, FakePhotoDataSource());
    addTearDown(controller.dispose);

    await controller.save(const UpdatePatientRequest(fullName: 'Maria'));
    expect(
      controller.errorMessage,
      'Unable to save changes. Please try again.',
    );
  });

  test(
    'the unavailable default fails clearly instead of guessing a URL',
    () async {
      final controller = EditPatientController(
        patientId: 'patient-1',
        editDataSource: const UnavailablePatientEditDataSource(),
        photoDataSource: FakePhotoDataSource(),
      );
      addTearDown(controller.dispose);

      expect(
        await controller.save(const UpdatePatientRequest(fullName: 'Maria')),
        isFalse,
      );
      expect(controller.errorMessage, contains('isn’t available yet'));
    },
  );

  PatientPhotoUpload photo() => PatientPhotoUpload(
    bytes: Uint8List.fromList([1, 2, 3]),
    filename: 'p.png',
    contentType: 'image/png',
  );

  test('uploads a new photo after the profile saves', () async {
    final photos = FakePhotoDataSource();
    final controller = _controller(FakePatientEditDataSource(), photos);
    addTearDown(controller.dispose);

    await controller.save(
      const UpdatePatientRequest(fullName: 'Maria'),
      photo: photo(),
    );
    expect(photos.uploads, ['p.png']);
    expect(
      controller.result!.patient.profilePhotoUrl,
      'https://example.com/new.png',
    );
  });

  test('a photo failure still counts as saved but is flagged', () async {
    final photos = FakePhotoDataSource()..failUpload = true;
    final controller = _controller(FakePatientEditDataSource(), photos);
    addTearDown(controller.dispose);

    expect(
      await controller.save(
        const UpdatePatientRequest(fullName: 'Maria'),
        photo: photo(),
      ),
      isTrue,
    );
    expect(controller.result!.photoFailed, isTrue);
  });

  test('patient list reflects a saved edit immediately', () {
    final list = CaregiverPatientController(dataSource: _NoopRead());
    addTearDown(list.dispose);
    final original = PatientListItemDto.fromJson(editPatientJson());
    list.patients = [original];
    var notified = 0;
    list.addListener(() => notified++);

    list.applyPatientUpdate(
      PatientDetailDto.fromJson(
        editPatientJson(name: 'Maria S.', relationship: 'Mother'),
      ),
    );

    expect(notified, 1);
    expect(list.patients.single.fullName, 'Maria S.');
    expect(list.patients.single.relationshipLabel, 'Mother');
    // The live health summary is kept.
    expect(list.patients.single.currentSummary, same(original.currentSummary));
    expect(list.visiblePatients.single.relationship, 'Mother');
  });

  test('applying an update for an unknown patient is a no-op', () {
    final list = CaregiverPatientController(dataSource: _NoopRead());
    addTearDown(list.dispose);
    var notified = 0;
    list.addListener(() => notified++);
    list.applyPatientUpdate(editPatient());
    expect(notified, 0);
  });
}

class _NoopRead implements CaregiverPatientReadDataSource {
  @override
  Future<PaginatedPatientListDto> fetchPatients({
    int limit = 100,
    int offset = 0,
  }) => throw UnimplementedError();

  @override
  Future<PatientDetailDto> fetchPatient(String patientId) =>
      throw UnimplementedError();

  @override
  Future<List<MonitoringDeviceDto>> fetchMonitoringDevices(String patientId) =>
      throw UnimplementedError();
}
