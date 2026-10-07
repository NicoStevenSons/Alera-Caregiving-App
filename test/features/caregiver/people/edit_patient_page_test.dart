import 'dart:async';
import 'dart:typed_data';

import 'package:alera/features/caregiver/data/api/caregiver_patient_api_data_source.dart';
import 'package:alera/features/caregiver/data/patients/edit_patient_controller.dart';
import 'package:alera/features/caregiver/presentation/people/edit_patient_page.dart';
import 'package:alera/features/caregiver/presentation/people/widgets/patient_photo_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'edit_patient_test_support.dart';

void main() {
  late FakePatientEditDataSource edit;
  late FakePhotoDataSource photos;
  EditPatientResult? popped;

  setUp(() {
    edit = FakePatientEditDataSource();
    photos = FakePhotoDataSource();
    popped = null;
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    PatientPhotoPickerFn? pickPhoto,
    String? relationship,
  }) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('open'),
                onPressed: () async {
                  popped = await Navigator.of(context).push(
                    MaterialPageRoute<EditPatientResult>(
                      builder: (_) => EditPatientPage(
                        patient: editPatient(relationship: relationship),
                        editDataSource: edit,
                        photoDataSource: photos,
                        pickPhoto: pickPhoto,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
  }

  String text(WidgetTester tester, String key) => tester
      .widget<TextFormField>(find.byKey(Key(key)))
      .controller!
      .text;

  testWidgets('pre-fills the existing patient information', (tester) async {
    await pumpPage(tester, relationship: 'Mother');

    expect(text(tester, 'edit-name-field'), 'Maria Santos');
    expect(text(tester, 'edit-phone-field'), '09123456789');
    expect(text(tester, 'edit-address-field'), 'Room 4');
    expect(text(tester, 'edit-emergency-name-field'), 'Juan');
    expect(text(tester, 'edit-emergency-phone-field'), '555-0100');
    expect(text(tester, 'edit-conditions-field'), 'Hypertension');
    expect(text(tester, 'edit-medications-field'), 'Medication A');
    expect(text(tester, 'edit-notes-field'), 'Morning checks');
    expect(text(tester, 'relationship-field'), 'Mother');
    expect(
      tester.widget<TextField>(find.byKey(const Key('edit-birth-day-field'))).controller!.text,
      '03',
    );
    expect(
      tester.widget<TextField>(find.byKey(const Key('edit-birth-month-field'))).controller!.text,
      '02',
    );
    expect(
      tester.widget<TextField>(find.byKey(const Key('edit-birth-year-field'))).controller!.text,
      '1950',
    );
    // No monitoring thresholds in the general form.
    expect(find.textContaining('heart rate'), findsNothing);
    expect(find.textContaining('SpO'), findsNothing);
  });

  testWidgets('requires a name and does not call the backend', (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byKey(const Key('edit-name-field')), '   ');
    await tester.tap(find.byKey(const Key('edit-patient-save')));
    await tester.pump();

    expect(find.text('Enter the patient’s full name.'), findsOneWidget);
    expect(edit.requests, isEmpty);
  });

  testWidgets('rejects an invalid birthdate', (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byKey(const Key('edit-birth-month-field')), '13');
    await tester.tap(find.byKey(const Key('edit-patient-save')));
    await tester.pump();

    expect(find.byKey(const Key('edit-birthdate-error')), findsOneWidget);
    expect(edit.requests, isEmpty);
  });

  testWidgets('saves normalized values and returns the result', (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byKey(const Key('edit-name-field')), '  Maria S.  ');
    await tester.enterText(
      find.byKey(const Key('relationship-field')),
      '  Grand   mother ',
    );
    await tester.tap(find.byKey(const Key('edit-patient-save')));
    await tester.pumpAndSettle();

    final sent = edit.requests.single;
    expect(sent.fullName.trim(), 'Maria S.');
    expect(sent.relationshipLabel, '  Grand   mother ');
    expect(sent.toJson()['relationship_label'], 'Grand mother');
    expect(sent.birthdate, DateTime(1950, 2, 3));
    expect(popped?.patient.fullName, 'Maria S.');
    expect(find.byKey(const Key('edit-patient-form')), findsNothing);
  });

  testWidgets('relationship suggestions fill the field; custom text works', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(const Key('relationship-suggestion-Client')));
    await tester.pump();
    expect(text(tester, 'relationship-field'), 'Client');

    await tester.enterText(
      find.byKey(const Key('relationship-field')),
      'Neighbour',
    );
    await tester.tap(find.byKey(const Key('edit-patient-save')));
    await tester.pumpAndSettle();
    expect(edit.requests.single.relationshipLabel, 'Neighbour');
  });

  testWidgets('a blank relationship clears it', (tester) async {
    await pumpPage(tester, relationship: 'Mother');
    await tester.enterText(find.byKey(const Key('relationship-field')), '   ');
    await tester.tap(find.byKey(const Key('edit-patient-save')));
    await tester.pumpAndSettle();
    expect(edit.requests.single.toJson()['relationship_label'], isNull);
  });

  testWidgets('limits the relationship to 50 characters', (tester) async {
    await pumpPage(tester);
    await tester.enterText(
      find.byKey(const Key('relationship-field')),
      'a' * 80,
    );
    expect(text(tester, 'relationship-field').length, 50);
  });

  testWidgets('shows saving state and blocks double submission', (tester) async {
    edit.gate = Completer<void>();
    await pumpPage(tester);
    await tester.tap(find.byKey(const Key('edit-patient-save')));
    await tester.pump();

    expect(find.text('Saving…'), findsOneWidget);
    await tester.tap(find.byKey(const Key('edit-patient-save')), warnIfMissed: false);
    await tester.pump();
    expect(edit.requests, hasLength(1));

    edit.gate!.complete();
    await tester.pumpAndSettle();
    expect(popped, isNotNull);
  });

  testWidgets('a failed save keeps the draft, shows the error, and retries', (
    tester,
  ) async {
    edit.failure = const CaregiverPatientApiFailure('Server is busy.');
    await pumpPage(tester);
    await tester.enterText(find.byKey(const Key('edit-name-field')), 'Maria Edited');
    await tester.enterText(find.byKey(const Key('edit-notes-field')), 'New notes');
    await tester.tap(find.byKey(const Key('edit-patient-save')));
    await tester.pumpAndSettle();

    expect(find.text('Server is busy.'), findsOneWidget);
    expect(find.byKey(const Key('edit-patient-form')), findsOneWidget);
    expect(text(tester, 'edit-name-field'), 'Maria Edited');
    expect(text(tester, 'edit-notes-field'), 'New notes');
    expect(find.text('Try again'), findsOneWidget);

    edit.failure = null;
    await tester.tap(find.byKey(const Key('edit-patient-save')));
    await tester.pumpAndSettle();
    expect(edit.requests, hasLength(2));
    expect(edit.requests.last.fullName, 'Maria Edited');
    expect(popped?.patient.fullName, 'Maria Edited');
  });

  testWidgets('a picked photo is previewed and uploaded after saving', (
    tester,
  ) async {
    await pumpPage(
      tester,
      pickPhoto: () async => PatientPhotoUpload(
        bytes: _tinyPng,
        filename: 'new.png',
        contentType: 'image/png',
      ),
    );
    await tester.tap(find.byKey(const Key('edit-choose-photo')));
    await tester.pump();
    expect(find.byKey(const Key('edit-patient-photo-preview')), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit-patient-save')));
    await tester.pumpAndSettle();
    expect(photos.uploads, ['new.png']);
    expect(popped?.patient.profilePhotoUrl, 'https://example.com/new.png');
  });

  testWidgets('photo errors are shown without losing the form', (tester) async {
    await pumpPage(
      tester,
      pickPhoto: () async =>
          throw const PatientPhotoException('Choose a JPEG, PNG, or WebP image.'),
    );
    await tester.tap(find.byKey(const Key('edit-choose-photo')));
    await tester.pump();
    expect(find.byKey(const Key('edit-photo-error')), findsOneWidget);
    expect(text(tester, 'edit-name-field'), 'Maria Santos');
  });
}

final Uint8List _tinyPng = Uint8List.fromList(const <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xFF, 0xFF, 0x3F,
  0x00, 0x05, 0xFE, 0x02, 0xFE, 0xA7, 0x35, 0x81, 0x84, 0x00, 0x00, 0x00,
  0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);
