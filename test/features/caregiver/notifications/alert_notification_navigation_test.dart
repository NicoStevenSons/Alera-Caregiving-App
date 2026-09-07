import 'dart:async';

import 'package:alera/features/caregiver/caregiver_shell.dart';
import 'package:alera/features/caregiver/data/api/caregiver_alert_api_data_source.dart';
import 'package:alera/features/caregiver/data/mock/mock_caregiver_repository.dart';
import 'package:alera/features/caregiver/domain/models/caregiver_alert.dart';
import 'package:alera/features/caregiver/presentation/alerts/caregiver_alert_detail_page.dart';
import 'package:alera/services/alert_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const alertId = '12345678-1234-1234-1234-123456789abc';
AlertNotification get event => AlertNotification.parse({
  'type': 'ALERT',
  'alert_id': alertId,
}, messageId: 'notification-1')!;

CaregiverAlert alert({
  String patient = 'remote-patient',
  CaregiverAlertStatus status = CaregiverAlertStatus.active,
}) => CaregiverAlert(
  id: alertId,
  careRecipientId: patient,
  patientDisplayName: 'Remote patient',
  title: 'Exact remote alert',
  description: 'Remote description',
  severity: CaregiverAlertSeverity.warning,
  metric: CaregiverAlertMetric.heartRate,
  status: status,
  reading: 120,
  threshold: 100,
  unit: 'BPM',
  triggerDuration: null,
  detectedAt: DateTime(2026, 9, 5),
  timeline: const [],
);

Future<void> mount(
  WidgetTester tester,
  NotificationTapBus bus,
  Future<CaregiverAlert> Function(String) load,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: CaregiverShell(
        repository: const MockCaregiverRepository(),
        alertDataSource: _EmptyAlerts(),
        notificationTapBus: bus,
        loadNotificationAlert: load,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final patient in ['maria-santos', 'remote-patient']) {
    testWidgets('loads exact cold-start alert and resolves patient $patient', (
      tester,
    ) async {
      final bus = NotificationTapBus();
      final result = alert(patient: patient);
      final requested = <String>[];
      bus.handle(event);
      await mount(tester, bus, (id) async {
        requested.add(id);
        return result;
      });
      expect(requested, [alertId]);
      final page = tester.widget<CaregiverAlertDetailPage>(
        find.byType(CaregiverAlertDetailPage),
      );
      expect(page.alert, same(result));
      expect(
        page.careRecipient?.id,
        patient == 'maria-santos' ? patient : null,
      );
      bus.handle(event);
      await tester.pumpAndSettle();
      expect(requested, [alertId]);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(CaregiverAlertDetailPage), findsNothing);
    });
  }

  testWidgets('duplicate tap during load performs one request and push', (
    tester,
  ) async {
    final bus = NotificationTapBus();
    final completer = Completer<CaregiverAlert>();
    var requests = 0;
    await mount(tester, bus, (_) {
      requests++;
      return completer.future;
    });
    bus.handle(event);
    bus.handle(event);
    expect(requests, 1);
    completer.complete(alert());
    await tester.pumpAndSettle();
    expect(find.byType(CaregiverAlertDetailPage), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(CaregiverAlertDetailPage), findsNothing);
  });

  testWidgets('invalid notification never requests or opens a detail', (
    tester,
  ) async {
    final bus = NotificationTapBus();
    var requests = 0;
    await mount(tester, bus, (_) async {
      requests++;
      return alert();
    });
    bus.handle(
      AlertNotification.parse({'type': 'ALERT', 'alert_id': '../other'}),
    );
    bus.handle(AlertNotification.parse({'type': 'OTHER', 'alert_id': alertId}));
    await tester.pumpAndSettle();
    expect(requests, 0);
    expect(find.byType(CaregiverAlertDetailPage), findsNothing);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  testWidgets('shell without authenticated loader does not consume taps', (
    tester,
  ) async {
    final bus = NotificationTapBus();
    await tester.pumpWidget(
      MaterialApp(
        home: CaregiverShell(
          repository: const MockCaregiverRepository(),
          alertDataSource: _EmptyAlerts(),
          notificationTapBus: bus,
        ),
      ),
    );
    await tester.pumpAndSettle();
    bus.handle(event);
    await tester.pumpAndSettle();
    expect(find.byType(CaregiverAlertDetailPage), findsNothing);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  testWidgets('401 leaves navigation to the auth gate', (tester) async {
    final bus = NotificationTapBus();
    await mount(
      tester,
      bus,
      (_) async => throw const CaregiverAlertsAuthFailure(401),
    );
    bus.handle(event);
    await tester.pumpAndSettle();
    expect(find.byType(CaregiverAlertDetailPage), findsNothing);
    expect(find.text('This alert is no longer available.'), findsNothing);
  });

  for (final failure in ['404', '403', 'network', 'resolved']) {
    testWidgets('$failure selects Alerts without mock detail', (tester) async {
      final bus = NotificationTapBus();
      await mount(tester, bus, (_) async {
        if (failure == 'resolved') {
          return alert(status: CaregiverAlertStatus.resolved);
        }
        if (failure == '403') throw const CaregiverAlertsAuthFailure(403);
        if (failure == '404') throw CaregiverAlertsHttpFailure(404);
        throw Exception('private server information');
      });
      bus.handle(event);
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );
      expect(find.text('This alert is no longer available.'), findsOneWidget);
      expect(find.byType(CaregiverAlertDetailPage), findsNothing);
      expect(find.text('private server information'), findsNothing);
    });
  }

  testWidgets('disposed caregiver shell cannot navigate after load', (
    tester,
  ) async {
    final bus = NotificationTapBus();
    final completer = Completer<CaregiverAlert>();
    await mount(tester, bus, (_) => completer.future);
    bus.handle(event);
    await tester.pumpWidget(const MaterialApp(home: Text('Signed out')));
    completer.complete(alert());
    await tester.pumpAndSettle();
    expect(find.byType(CaregiverAlertDetailPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _EmptyAlerts implements CaregiverAlertDataSource {
  @override
  Future<List<CaregiverAlert>> fetchAlerts() async => [];
}
