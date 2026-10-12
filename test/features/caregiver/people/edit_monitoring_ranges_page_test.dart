import 'package:alera/features/caregiver/data/api/caregiver_patient_api_data_source.dart';
import 'package:alera/features/caregiver/data/api/dto/patient_dto.dart';
import 'package:alera/features/caregiver/presentation/people/edit_monitoring_ranges_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'edit_patient_test_support.dart';

void main() {
  late FakePhotoDataSource source;
  MonitoringSettingsResponse? popped;

  setUp(() {
    source = FakePhotoDataSource();
    popped = null;
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    bool customRanges = false,
  }) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              key: const Key('open'),
              onPressed: () async {
                popped = await Navigator.of(context).push(
                  MaterialPageRoute<MonitoringSettingsResponse>(
                    builder: (_) => EditMonitoringRangesPage(
                      patient: editPatient(customRanges: customRanges),
                      dataSource: source,
                    ),
                  ),
                );
              },
              child: const Text('open'),
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

  test('summary describes defaults and custom ranges', () {
    expect(monitoringRangesSummary(editPatient()), 'Alera defaults');
    expect(
      monitoringRangesSummary(editPatient(customRanges: true)),
      'Heart rate 55–105 bpm · SpO₂ 92–99%',
    );
  });

  testWidgets('defaults patient opens with defaults and no range fields', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(find.byKey(const Key('monitoring-hr-min-field')), findsNothing);
  });

  testWidgets('custom patient opens pre-filled', (tester) async {
    await pumpPage(tester, customRanges: true);
    expect(text(tester, 'monitoring-hr-min-field'), '55');
    expect(text(tester, 'monitoring-hr-max-field'), '105');
    expect(text(tester, 'monitoring-spo2-min-field'), '92');
    expect(text(tester, 'monitoring-spo2-max-field'), '99');
  });

  testWidgets('saves custom ranges and pops the server response', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(const Key('monitoring-custom-option')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('monitoring-hr-min-field')),
      '50',
    );
    await tester.enterText(
      find.byKey(const Key('monitoring-hr-max-field')),
      '110',
    );
    await tester.enterText(
      find.byKey(const Key('monitoring-spo2-min-field')),
      '93',
    );
    await tester.tap(find.byKey(const Key('edit-monitoring-save')));
    await tester.pumpAndSettle();

    final sent = source.monitoringRequests.single;
    expect(sent.toJson(), {
      'normal_hr_min': 50,
      'normal_hr_max': 110,
      'usual_spo2_min': 93,
      'usual_spo2_max': null,
    });
    expect(popped!.thresholdMode, PatientThresholdMode.custom);
    expect(popped!.normalHrMax, 110);
  });

  testWidgets('Use Alera defaults saves the built-in ranges', (tester) async {
    await pumpPage(tester, customRanges: true);
    await tester.tap(find.byKey(const Key('monitoring-default-option')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-monitoring-save')));
    await tester.pumpAndSettle();

    expect(source.monitoringRequests.single.toJson(), {
      'normal_hr_min': 60,
      'normal_hr_max': 100,
      'usual_spo2_min': 95,
      'usual_spo2_max': null,
    });
    expect(popped!.thresholdMode, PatientThresholdMode.defaultMode);
  });

  testWidgets('blank and out-of-range values do not reach the backend', (
    tester,
  ) async {
    await pumpPage(tester, customRanges: true);
    await tester.enterText(
      find.byKey(const Key('monitoring-hr-min-field')),
      '',
    );
    await tester.enterText(
      find.byKey(const Key('monitoring-spo2-min-field')),
      '101',
    );
    await tester.tap(find.byKey(const Key('edit-monitoring-save')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a minimum heart rate.'), findsOneWidget);
    expect(find.text('Enter a minimum SpO₂ from 0 to 100.'), findsOneWidget);
    expect(source.monitoringRequests, isEmpty);
    expect(popped, isNull);
  });

  testWidgets('minimum above maximum is rejected', (tester) async {
    await pumpPage(tester, customRanges: true);
    await tester.enterText(
      find.byKey(const Key('monitoring-hr-min-field')),
      '120',
    );
    await tester.tap(find.byKey(const Key('edit-monitoring-save')));
    await tester.pumpAndSettle();

    expect(
      find.text('Heart rate minimum must not be above the maximum.'),
      findsOneWidget,
    );
    expect(source.monitoringRequests, isEmpty);
  });

  testWidgets('a failed save shows the message, keeps values and retries', (
    tester,
  ) async {
    source.monitoringFailure = const CaregiverPatientApiFailure(
      'Ranges rejected.',
    );
    await pumpPage(tester, customRanges: true);
    await tester.enterText(
      find.byKey(const Key('monitoring-hr-max-field')),
      '120',
    );
    await tester.tap(find.byKey(const Key('edit-monitoring-save')));
    await tester.pumpAndSettle();

    expect(find.text('Ranges rejected.'), findsOneWidget);
    expect(text(tester, 'monitoring-hr-max-field'), '120');
    expect(find.text('Try again'), findsOneWidget);
    expect(popped, isNull);

    source.monitoringFailure = null;
    await tester.tap(find.byKey(const Key('edit-monitoring-save')));
    await tester.pumpAndSettle();
    expect(popped!.normalHrMax, 120);
    expect(source.monitoringRequests, hasLength(2));
  });
}
