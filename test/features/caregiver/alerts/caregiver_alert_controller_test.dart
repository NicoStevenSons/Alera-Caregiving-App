import 'dart:async';

import 'package:alera/features/caregiver/data/alerts/caregiver_alert_controller.dart';
import 'package:alera/features/caregiver/data/api/caregiver_alert_api_data_source.dart';
import 'package:alera/features/caregiver/domain/models/caregiver_alert.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('successful action replaces matching shared alert', () async {
    final active = _alert(CaregiverAlertStatus.active);
    final resolved = _alert(CaregiverAlertStatus.resolved);
    final controller = CaregiverAlertController(
      loader: _Loader([active]),
      actions: _Actions(result: resolved),
    );
    await controller.load();

    final result = await controller.resolve(active.id);

    expect(result.status, CaregiverAlertStatus.resolved);
    expect(controller.alerts.single, same(resolved));
  });

  test('failed action does not mutate shared alert state', () async {
    final active = _alert(CaregiverAlertStatus.active);
    final controller = CaregiverAlertController(
      loader: _Loader([active]),
      actions: _Actions(fail: true),
    );
    await controller.load();

    await expectLater(
      controller.acknowledge(active.id),
      throwsA(isA<CaregiverAlertsRequestFailure>()),
    );

    expect(controller.alerts.single, same(active));
    expect(controller.isBusy(active.id), isFalse);
  });

  test('duplicate action is rejected while first request is running', () async {
    final active = _alert(CaregiverAlertStatus.active);
    final actions = _Actions(result: _alert(CaregiverAlertStatus.acknowledged));
    final controller = CaregiverAlertController(
      loader: _Loader([active]),
      actions: actions,
    );
    await controller.load();
    actions.hold = true;

    final first = controller.acknowledge(active.id);
    await expectLater(
      controller.acknowledge(active.id),
      throwsA(isA<CaregiverAlertActionFailure>()),
    );
    actions.release();
    await first;
    expect(actions.calls, 1);
  });
}

class _Loader implements CaregiverAlertDataSource {
  final List<CaregiverAlert> values;
  const _Loader(this.values);
  @override
  Future<List<CaregiverAlert>> fetchAlerts() async => values;
}

class _Actions implements CaregiverAlertActionDataSource {
  final CaregiverAlert? result;
  final bool fail;
  bool hold = false;
  int calls = 0;
  Completer<void>? _pending;

  _Actions({this.result, this.fail = false});

  void release() {
    _pending?.complete();
    _pending = null;
  }

  Future<CaregiverAlert> _run() async {
    calls++;
    if (hold) {
      _pending = Completer<void>();
      await _pending!.future;
    }
    if (fail) throw CaregiverAlertsRequestFailure('offline');
    return result!;
  }

  @override
  Future<CaregiverAlert> acknowledge(String alertId, {String? note}) => _run();
  @override
  Future<CaregiverAlert> addNote(String alertId, String note) => _run();
  @override
  Future<CaregiverAlert> logIntervention(
    String alertId,
    CaregiverInterventionType interventionType,
    String note,
  ) => _run();
  @override
  Future<CaregiverAlert> markFalseAlarm(String alertId, String reason) =>
      _run();
  @override
  Future<CaregiverAlert> resolve(String alertId, {String? note}) => _run();
}

CaregiverAlert _alert(CaregiverAlertStatus status) => CaregiverAlert(
  id: 'alert-1',
  careRecipientId: 'patient-1',
  title: 'High Heart Rate',
  description: 'Threshold exceeded',
  severity: CaregiverAlertSeverity.warning,
  metric: CaregiverAlertMetric.heartRate,
  status: status,
  reading: 120,
  threshold: 100,
  unit: 'BPM',
  triggerDuration: const Duration(minutes: 5),
  detectedAt: DateTime.utc(2026, 9, 6),
  timeline: const [],
);
