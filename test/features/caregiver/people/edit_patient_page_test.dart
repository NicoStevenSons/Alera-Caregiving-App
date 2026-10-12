import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:alera/features/caregiver/data/api/caregiver_patient_api_data_source.dart';
import 'package:alera/features/caregiver/data/api/caregiver_patient_archive_data_source.dart';
import 'package:alera/features/caregiver/data/auth/caregiver_session_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:alera/features/caregiver/data/api/dto/patient_dto.dart';
import 'package:alera/features/caregiver/data/patients/edit_patient_controller.dart';
import 'package:alera/features/caregiver/presentation/people/edit_patient_page.dart';
import 'package:alera/features/caregiver/presentation/people/widgets/patient_photo_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'edit_patient_test_support.dart';

void main() {
  late FakePatientEditDataSource edit;
  late FakePhotoDataSource photos;
  late FakeArchiveDataSource archive;
  EditPatientResult? popped;

  setUp(() {
    edit = FakePatientEditDataSource();
    photos = FakePhotoDataSource();
    archive = FakeArchiveDataSource();
    popped = null;
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    PatientPhotoPickerFn? pickPhoto,
    String? relationship,
    bool customRanges = false,
    CaregiverPatientArchiveDataSource? archiveSource,
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
                        patient: editPatient(
                          relationship: relationship,
                          customRanges: customRanges,
                        ),
                        editDataSource: edit,
                        photoDataSource: photos,
                        archiveDataSource: archiveSource ?? archive,
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

  String text(WidgetTester tester, String key) =>
      tester.widget<TextFormField>(find.byKey(Key(key))).controller!.text;

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
    expect(relationshipSelected(tester, 'Mother'), isTrue);
    expect(relationshipSelected(tester, 'Father'), isFalse);
    expect(find.byKey(const Key('relationship-other-field')), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('edit-birth-day-field')))
          .controller!
          .text,
      '03',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('edit-birth-month-field')))
          .controller!
          .text,
      '02',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('edit-birth-year-field')))
          .controller!
          .text,
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
    await tester.enterText(
      find.byKey(const Key('edit-birth-month-field')),
      '13',
    );
    await tester.tap(find.byKey(const Key('edit-patient-save')));
    await tester.pump();

    expect(find.byKey(const Key('edit-birthdate-error')), findsOneWidget);
    expect(edit.requests, isEmpty);
  });

  testWidgets('saves normalized values and returns the result', (tester) async {
    await pumpPage(tester);
    await tester.enterText(
      find.byKey(const Key('edit-name-field')),
      '  Maria S.  ',
    );
    await pickRelationship(tester, 'Other');
    await tester.enterText(
      find.byKey(const Key('relationship-other-field')),
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

  testWidgets('tapping a relationship tile saves it', (tester) async {
    await pumpPage(tester);
    // One compact control: no second text box until "Other" is tapped.
    expect(find.byKey(const Key('relationship-other-field')), findsNothing);

    await pickRelationship(tester, 'Client');
    expect(find.byKey(const Key('relationship-other-field')), findsNothing);
    await tester.tap(find.byKey(const Key('edit-patient-save')));
    await tester.pumpAndSettle();
    expect(edit.requests.single.relationshipLabel, 'Client');
  });

  testWidgets('Other reveals a text box for a custom relationship', (
    tester,
  ) async {
    await pumpPage(tester);
    await pickRelationship(tester, 'Other');
    await tester.enterText(
      find.byKey(const Key('relationship-other-field')),
      'Neighbour',
    );
    await tester.tap(find.byKey(const Key('edit-patient-save')));
    await tester.pumpAndSettle();
    expect(edit.requests.single.relationshipLabel, 'Neighbour');
  });

  testWidgets('a saved custom relationship opens in the text box', (
    tester,
  ) async {
    await pumpPage(tester, relationship: 'Neighbour');
    expect(text(tester, 'relationship-other-field'), 'Neighbour');
    expect(relationshipSelected(tester, 'Other'), isTrue);
  });

  testWidgets('tapping the selected tile clears the relationship', (
    tester,
  ) async {
    await pumpPage(tester, relationship: 'Mother');
    await pickRelationship(tester, 'Mother');
    expect(relationshipSelected(tester, 'Mother'), isFalse);
    await tester.tap(find.byKey(const Key('edit-patient-save')));
    await tester.pumpAndSettle();
    expect(edit.requests.single.toJson()['relationship_label'], isNull);
  });

  testWidgets('limits a custom relationship to 50 characters', (tester) async {
    await pumpPage(tester);
    await pickRelationship(tester, 'Other');
    await tester.enterText(
      find.byKey(const Key('relationship-other-field')),
      'a' * 80,
    );
    expect(text(tester, 'relationship-other-field').length, 50);
  });

  testWidgets('shows saving state and blocks double submission', (
    tester,
  ) async {
    edit.gate = Completer<void>();
    await pumpPage(tester);
    await tester.tap(find.byKey(const Key('edit-patient-save')));
    await tester.pump();

    expect(find.text('Saving…'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('edit-patient-save')),
      warnIfMissed: false,
    );
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
    await tester.enterText(
      find.byKey(const Key('edit-name-field')),
      'Maria Edited',
    );
    await tester.enterText(
      find.byKey(const Key('edit-notes-field')),
      'New notes',
    );
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
      pickPhoto: () async => throw const PatientPhotoException(
        'Choose a JPEG, PNG, or WebP image.',
      ),
    );
    await tester.tap(find.byKey(const Key('edit-choose-photo')));
    await tester.pump();
    expect(find.byKey(const Key('edit-photo-error')), findsOneWidget);
    expect(text(tester, 'edit-name-field'), 'Maria Santos');
  });

  group('monitoring ranges', () {
    String summary(WidgetTester tester) => tester
        .widget<Text>(find.byKey(const Key('edit-monitoring-summary')))
        .data!;

    testWidgets('row shows the current ranges summary', (tester) async {
      await pumpPage(tester);
      await tester.ensureVisible(
        find.byKey(const Key('edit-monitoring-ranges')),
      );
      expect(summary(tester), 'Alera defaults');
    });

    testWidgets('saving ranges updates the row without saving the profile', (
      tester,
    ) async {
      await pumpPage(tester);
      final row = find.byKey(const Key('edit-monitoring-ranges'));
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('monitoring-custom-option')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('monitoring-hr-min-field')),
        '50',
      );
      await tester.tap(find.byKey(const Key('edit-monitoring-save')));
      await tester.pumpAndSettle();

      expect(photos.monitoringRequests.single.normalHrMin, 50);
      expect(edit.requests, isEmpty);
      expect(summary(tester), startsWith('Heart rate 50–100 bpm'));
    });

    testWidgets('cancelling the profile form keeps saved ranges', (
      tester,
    ) async {
      await pumpPage(tester);
      final row = find.byKey(const Key('edit-monitoring-ranges'));
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('monitoring-custom-option')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('monitoring-hr-min-field')),
        '50',
      );
      await tester.tap(find.byKey(const Key('edit-monitoring-save')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit-patient-form')), findsNothing);
      expect(popped, isNotNull);
      expect(popped!.archived, isFalse);
      expect(popped!.patient.thresholdMode, PatientThresholdMode.custom);
    });

    testWidgets('cancelling without a change returns nothing', (tester) async {
      await pumpPage(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(popped, isNull);
    });
  });

  group('archive patient', () {
    Future<void> openDialog(WidgetTester tester) async {
      final button = find.byKey(const Key('edit-archive-patient'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    testWidgets('asks for confirmation before doing anything', (tester) async {
      await pumpPage(tester);
      await openDialog(tester);

      expect(find.byKey(const Key('archive-patient-dialog')), findsOneWidget);
      expect(find.text('Archive Maria Santos?'), findsOneWidget);
      expect(archive.archived, isEmpty);
    });

    testWidgets('cancel closes the dialog and archives nothing', (
      tester,
    ) async {
      await pumpPage(tester);
      await openDialog(tester);
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('archive-patient-dialog')),
          matching: find.text('Cancel'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('archive-patient-dialog')), findsNothing);
      expect(find.byKey(const Key('edit-patient-form')), findsOneWidget);
      expect(archive.archived, isEmpty);
      expect(popped, isNull);
    });

    testWidgets('confirming archives the patient and closes the page', (
      tester,
    ) async {
      await pumpPage(tester);
      await openDialog(tester);
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(archive.archived, ['patient-1']);
      expect(popped!.archived, isTrue);
      expect(popped!.patient.patientId, 'patient-1');
      expect(find.byKey(const Key('edit-patient-form')), findsNothing);
    });

    testWidgets('shows busy state while archiving', (tester) async {
      archive.gate = Completer<void>();
      await pumpPage(tester);
      await openDialog(tester);
      await tester.tap(find.text('Archive'));
      await tester.pump();

      expect(find.text('Archiving…'), findsOneWidget);
      expect(archive.archived, isEmpty);

      archive.gate!.complete();
      await tester.pumpAndSettle();
      expect(archive.archived, ['patient-1']);
    });

    testWidgets('a failure stays in the dialog and keeps the page', (
      tester,
    ) async {
      archive.failure = const CaregiverPatientApiFailure('Cannot archive.');
      await pumpPage(tester);
      await openDialog(tester);
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('archive-patient-dialog')), findsOneWidget);
      expect(find.text('Cannot archive.'), findsOneWidget);
      expect(popped, isNull);

      archive.failure = null;
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      expect(archive.archived, ['patient-1']);
      expect(popped!.archived, isTrue);
    });

    testWidgets('the default data source reports archiving is unavailable', (
      tester,
    ) async {
      await expectLater(
        const UnavailablePatientArchiveDataSource().archivePatient('p'),
        throwsA(isA<CaregiverPatientApiFailure>()),
      );
    });
  });

  group('archive patient through the real API data source', () {
    CaregiverPatientApiDataSource api(MockClient client) =>
        CaregiverPatientApiDataSource(session: _TokenSession(), client: client);

    Future<void> confirm(WidgetTester tester) async {
      final button = find.byKey(const Key('edit-archive-patient'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
    }

    testWidgets('HTTP 200 archives and closes the page', (tester) async {
      final requests = <http.Request>[];
      await pumpPage(
        tester,
        archiveSource: api(
          MockClient((request) async {
            requests.add(request);
            return http.Response(
              jsonEncode({
                'patient_id': 'patient-1',
                'archived_at': '2026-10-12T15:30:05Z',
              }),
              200,
            );
          }),
        ),
      );
      await confirm(tester);
      await tester.pumpAndSettle();

      expect(requests.single.url.path, '/api/v1/patients/patient-1/archive');
      expect(requests.single.headers['authorization'], 'Bearer t');
      expect(popped!.archived, isTrue);
    });

    testWidgets('a backend detail message appears in the open dialog', (
      tester,
    ) async {
      await pumpPage(
        tester,
        archiveSource: api(
          MockClient(
            (_) async => http.Response(
              jsonEncode({'detail': 'Caregiver role required.'}),
              403,
            ),
          ),
        ),
      );
      await confirm(tester);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('archive-patient-dialog')), findsOneWidget);
      expect(find.text('Caregiver role required.'), findsOneWidget);
      expect(popped, isNull);
      expect(find.byKey(const Key('edit-patient-form')), findsOneWidget);
    });

    testWidgets('a second tap while the request runs sends nothing', (
      tester,
    ) async {
      final gate = Completer<void>();
      var calls = 0;
      await pumpPage(
        tester,
        archiveSource: api(
          MockClient((_) async {
            calls++;
            await gate.future;
            return http.Response(
              jsonEncode({
                'patient_id': 'patient-1',
                'archived_at': '2026-10-12T15:30:05Z',
              }),
              200,
            );
          }),
        ),
      );
      await confirm(tester);
      await tester.pump();
      await tester.tap(find.text('Archiving…'), warnIfMissed: false);
      await tester.pump();

      expect(calls, 1);
      gate.complete();
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(popped!.archived, isTrue);
    });
  });
}

final Uint8List _tinyPng = Uint8List.fromList(const <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0xF8,
  0xFF,
  0xFF,
  0x3F,
  0x00,
  0x05,
  0xFE,
  0x02,
  0xFE,
  0xA7,
  0x35,
  0x81,
  0x84,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

class _TokenSession implements CaregiverSession {
  @override
  String? get accessToken => 't';
  @override
  String? get householdCode => null;
  @override
  Future<void> clearInvalidSession() async {}
}
