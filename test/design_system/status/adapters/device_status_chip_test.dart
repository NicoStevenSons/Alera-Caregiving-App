import 'package:alera/design_system/status/adapters/device_status_chip.dart';
import 'package:alera/design_system/status/alera_status_tone.dart';
import 'package:alera/features/caregiver/data/api/dto/patient_dto.dart'
    show PatientDeviceConnectionStatus;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('DeviceStatusChip', () {
    testWidgets('connected with no battery reading renders Online', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const DeviceStatusChip(PatientDeviceConnectionStatus.connected),
        ),
      );

      expect(find.text('Online'), findsOneWidget);
    });

    testWidgets('connected with battery above threshold renders Online', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const DeviceStatusChip(
            PatientDeviceConnectionStatus.connected,
            batteryPercent: 80,
          ),
        ),
      );

      expect(find.text('Online'), findsOneWidget);
    });

    testWidgets(
      'connected with battery at or below threshold renders Low battery '
      'instead of Online',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _host(
            const DeviceStatusChip(
              PatientDeviceConnectionStatus.connected,
              batteryPercent: 20,
            ),
          ),
        );

        expect(find.text('Low battery'), findsOneWidget);
        expect(find.text('Online'), findsNothing);
      },
    );

    testWidgets('a disconnected device with a low battery still reads '
        'Offline, not Low battery', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const DeviceStatusChip(
            PatientDeviceConnectionStatus.disconnected,
            batteryPercent: 5,
          ),
        ),
      );

      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Low battery'), findsNothing);
    });

    testWidgets('notConnected also renders Offline', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const DeviceStatusChip(PatientDeviceConnectionStatus.notConnected),
        ),
      );

      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('syncing renders the info tone', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const DeviceStatusChip(PatientDeviceConnectionStatus.syncing)),
      );

      expect(find.text('Syncing'), findsOneWidget);
    });

    testWidgets('failed renders as critical', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const DeviceStatusChip(PatientDeviceConnectionStatus.failed)),
      );

      expect(find.text('Sync failed'), findsOneWidget);
    });

    testWidgets('unknown renders a neutral placeholder', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const DeviceStatusChip(PatientDeviceConnectionStatus.unknown)),
      );

      expect(find.text('Unknown'), findsOneWidget);
    });

    testWidgets('a custom lowBatteryThreshold is respected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const DeviceStatusChip(
            PatientDeviceConnectionStatus.connected,
            batteryPercent: 30,
            lowBatteryThreshold: 40,
          ),
        ),
      );

      expect(find.text('Low battery'), findsOneWidget);
    });

    testWidgets('describe() gives disconnected and notConnected the same '
        'neutral tone', (WidgetTester tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (BuildContext context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final AleraStatusTone disconnected = DeviceStatusChip.describe(
        PatientDeviceConnectionStatus.disconnected,
        capturedContext,
      ).tone;
      final AleraStatusTone notConnected = DeviceStatusChip.describe(
        PatientDeviceConnectionStatus.notConnected,
        capturedContext,
      ).tone;

      expect(disconnected, AleraStatusTone.neutral);
      expect(notConnected, AleraStatusTone.neutral);
    });
  });
}
