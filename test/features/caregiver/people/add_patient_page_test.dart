import 'dart:convert';
import 'package:alera/features/caregiver/data/api/caregiver_patient_api_data_source.dart';
import 'package:alera/features/caregiver/data/api/dto/patient_dto.dart';
import 'package:alera/features/caregiver/presentation/people/add_patient_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'QR payload remains version 2',
    () => expect(jsonDecode(buildPatientAccessQrPayload(accessCode: 'ABC')), {
      'type': 'alera_patient_access',
      'version': 2,
      'access_code': 'ABC',
    }),
  );
  testWidgets(
    'starts setup, validates personal information, and preserves draft on Back',
    (t) async {
      final s = _Source();
      await pump(t, s);
      await startSetup(t);
      await t.tap(find.text('Continue'));
      await t.pump();
      expect(find.text('Enter the patient’s full name.'), findsOneWidget);
      await t.enterText(find.byKey(const Key('patient-name-field')), 'Ada');
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      expect(find.text('Care Information'), findsOneWidget);
      await t.tap(find.byTooltip('Back'));
      await t.pumpAndSettle();
      expect(
        t
            .widget<TextFormField>(find.byKey(const Key('patient-name-field')))
            .controller!
            .text,
        'Ada',
      );
    },
  );
  testWidgets(
    'skip care, default monitoring, review and confirmation post once',
    (t) async {
      final s = _Source();
      var callbacks = 0;
      await pump(
        t,
        s,
        onCreated: (_) async {
          callbacks++;
        },
      );
      await reachReview(t);
      expect(find.text('Alera defaults'), findsOneWidget);
      await t.tap(find.text('Create patient').first);
      await t.pumpAndSettle();
      expect(s.createCalls, 0);
      await t.tap(find.text('Create patient').last);
      await t.pumpAndSettle();
      expect(s.createCalls, 1);
      expect(s.patchCalls, 0);
      expect(callbacks, 1);
      expect(find.text('Ada has been added'), findsOneWidget);
    },
  );
  testWidgets(
    'custom monitoring posts then patches and retry never posts again',
    (t) async {
      final s = _Source(patchFails: true);
      await pump(t, s);
      await reachMonitoring(t);
      await t.tap(find.byKey(const Key('custom-monitoring-option')));
      await t.pump();
      await t.enterText(find.byKey(const Key('hr-min-field')), '55');
      await t.enterText(find.byKey(const Key('hr-max-field')), '105');
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      await t.tap(find.text('Create patient').first);
      await t.pumpAndSettle();
      await t.tap(find.text('Create patient').last);
      await t.pumpAndSettle();
      expect(s.createCalls, 1);
      expect(s.patchCalls, 1);
      await t.tap(find.text('Retry settings'));
      await t.pumpAndSettle();
      expect(s.createCalls, 1);
      expect(s.patchCalls, 2);
    },
  );
  testWidgets(
    'finish and pairing generate code only when explicitly requested',
    (t) async {
      final s = _Source();
      await pump(t, s);
      await create(t);
      expect(s.issueCalls, 0);
      await t.tap(find.text('Finish for now'));
      await t.pumpAndSettle();
      expect(find.text('Finish setup for now?'), findsOneWidget);
      await t.tap(find.text('Continue setup'));
      await t.pumpAndSettle();
      await t.tap(find.text('Connect patient access'));
      await t.pumpAndSettle();
      expect(s.issueCalls, 0);
      await t.tap(find.text('Generate access code'));
      await t.pumpAndSettle();
      expect(s.issueCalls, 1);
      expect(find.byKey(const Key('issued-access-code')), findsOneWidget);
      expect(find.byKey(const Key('access-code-qr')), findsOneWidget);
      expect(find.text('HOME-123'), findsNothing);
    },
  );
}

Future<void> pump(
  WidgetTester t,
  _Source s, {
  Future<void> Function(PatientCreatedResponse)? onCreated,
}) => t.pumpWidget(
  MaterialApp(
    home: AddPatientPage(
      dataSource: s,
      householdCode: 'HOME-123',
      onPatientCreated: onCreated ?? (_) {},
    ),
  ),
);
Future<void> startSetup(WidgetTester t) async {
  await t.tap(find.text('Start setup'));
  await t.pumpAndSettle();
  expect(find.text('Personal Information'), findsOneWidget);
}

Future<void> completePersonalInformation(WidgetTester t) async {
  await t.enterText(find.byKey(const Key('patient-name-field')), 'Ada');
  await t.tap(find.text('Continue'));
  await t.pumpAndSettle();
}

Future<void> reachCareInformation(WidgetTester t) async {
  await startSetup(t);
  await completePersonalInformation(t);
}

Future<void> reachMonitoring(WidgetTester t) async {
  await reachCareInformation(t);
  await t.scrollUntilVisible(
    find.text('Skip for now'),
    400,
    scrollable: find.byType(Scrollable).first,
  );
  await t.tap(find.text('Skip for now'));
  await t.pumpAndSettle();
}

Future<void> reachReview(WidgetTester t) async {
  await reachMonitoring(t);
  await t.tap(find.text('Continue'));
  await t.pumpAndSettle();
}

Future<void> create(WidgetTester t) async {
  await reachReview(t);
  await t.tap(find.text('Create patient').first);
  await t.pumpAndSettle();
  await t.tap(find.text('Create patient').last);
  await t.pumpAndSettle();
}

class _Source implements CaregiverPatientDataSource {
  _Source({this.patchFails = false});
  final bool patchFails;
  int createCalls = 0, patchCalls = 0, issueCalls = 0;
  @override
  Future<PatientCreatedResponse> createPatient(CreatePatientRequest r) async {
    createCalls++;
    return _created();
  }

  @override
  Future<MonitoringSettingsResponse> updateMonitoringSettings(
    String id,
    UpdateMonitoringSettingsRequest r,
  ) async {
    patchCalls++;
    if (patchFails && patchCalls == 1) {
      throw const CaregiverPatientApiFailure('Settings rejected');
    }
    return MonitoringSettingsResponse(
      patientId: id,
      thresholdMode: PatientThresholdMode.custom,
      thresholdModeValue: 'CUSTOM',
      normalHrMin: r.normalHrMin,
      normalHrMax: r.normalHrMax,
      usualSpo2Min: r.usualSpo2Min,
      usualSpo2Max: r.usualSpo2Max,
      updatedAt: DateTime.utc(2026),
    );
  }

  @override
  Future<PatientAccessCodeResponse> createAccessCode(String id) async {
    issueCalls++;
    return PatientAccessCodeResponse(
      accessCodeId: 'c',
      patientId: id,
      accessCode: 'ONE-TIME-CODE',
      createdByUserId: 'u',
      createdAt: DateTime.utc(2026),
      expiresAt: DateTime.utc(2027, 1, 2),
      status: 'ACTIVE',
    );
  }
}

PatientCreatedResponse _created() => PatientCreatedResponse(
  patientId: 'p',
  userId: 'u',
  householdId: 'h',
  accountStatus: 'ACTIVE',
  assignment: null,
  fullName: 'Ada',
  birthdate: null,
  sex: null,
  phoneNumber: null,
  addressOrRoom: null,
  emergencyContactName: null,
  emergencyContactPhone: null,
  knownConditions: null,
  medications: null,
  baselineHeartRate: null,
  baselineSpo2: null,
  monitoringNotes: null,
  createdAt: DateTime.utc(2026),
);
