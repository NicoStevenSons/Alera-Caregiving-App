import 'package:flutter/material.dart';

import '../../../features/caregiver/data/api/dto/patient_dto.dart'
    show PatientDeviceConnectionStatus;
import '../alera_status_assets.dart';
import '../alera_status_chip.dart';
import '../alera_status_descriptor.dart';
import '../alera_status_glyph.dart';
import '../alera_status_labels.dart';
import '../alera_status_tone.dart';

/// Maps device connectivity (and, when known, battery level) to an
/// [AleraStatusChip].
///
/// Connection and battery are two independent facts about a device in the
/// data model — a connection-status enum and a separate raw battery
/// percentage — there is no single enum with a combined "low battery" state.
/// This adapter reflects that: it renders connection status by default, and
/// only shows a low-battery warning in place of "Connected" when the device
/// is actually connected and its battery is at or below [lowBatteryThreshold].
/// A disconnected device's battery reading is stale, so battery never
/// overrides a non-connected state.
class DeviceStatusChip extends StatelessWidget {
  final PatientDeviceConnectionStatus connectionStatus;

  /// 0–100, or null when unknown. Only consulted while [connectionStatus] is
  /// `connected`.
  final int? batteryPercent;

  /// No house convention exists yet for what counts as "low"; 20% is this
  /// adapter's default and can be overridden per call site.
  final int lowBatteryThreshold;

  final String? labelOverride;
  final AleraStatusChipSize size;

  const DeviceStatusChip(
    this.connectionStatus, {
    super.key,
    this.batteryPercent,
    this.lowBatteryThreshold = 20,
    this.labelOverride,
    this.size = AleraStatusChipSize.medium,
  });

  static AleraStatusDescriptor describe(
    PatientDeviceConnectionStatus connectionStatus,
    BuildContext context, {
    int? batteryPercent,
    int lowBatteryThreshold = 20,
  }) {
    final AleraStatusLabels labels = AleraStatusLabels.of(context);

    if (connectionStatus == PatientDeviceConnectionStatus.connected &&
        batteryPercent != null &&
        batteryPercent <= lowBatteryThreshold) {
      return AleraStatusDescriptor(
        tone: AleraStatusTone.warning,
        glyph: const AleraStatusGlyph(
          assetPath: AleraStatusAssets.deviceLowBattery,
          fallbackIcon: Icons.battery_alert,
        ),
        label: labels.deviceLowBattery,
      );
    }

    return switch (connectionStatus) {
      PatientDeviceConnectionStatus.connected => AleraStatusDescriptor(
        tone: AleraStatusTone.success,
        glyph: const AleraStatusGlyph.material(Icons.wifi),
        label: labels.deviceOnline,
      ),
      PatientDeviceConnectionStatus.syncing => AleraStatusDescriptor(
        tone: AleraStatusTone.info,
        glyph: const AleraStatusGlyph.material(Icons.sync),
        label: labels.deviceSyncing,
      ),
      PatientDeviceConnectionStatus.failed => AleraStatusDescriptor(
        tone: AleraStatusTone.critical,
        glyph: const AleraStatusGlyph.material(Icons.sync_problem),
        label: labels.deviceSyncFailed,
      ),
      PatientDeviceConnectionStatus.disconnected ||
      PatientDeviceConnectionStatus.notConnected => AleraStatusDescriptor(
        tone: AleraStatusTone.neutral,
        glyph: const AleraStatusGlyph.material(Icons.wifi_off),
        label: labels.deviceOffline,
      ),
      PatientDeviceConnectionStatus.unknown => AleraStatusDescriptor(
        tone: AleraStatusTone.neutral,
        glyph: const AleraStatusGlyph.material(Icons.help_outline),
        label: labels.deviceUnknown,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AleraStatusChip(
      descriptor: describe(
        connectionStatus,
        context,
        batteryPercent: batteryPercent,
        lowBatteryThreshold: lowBatteryThreshold,
      ),
      labelOverride: labelOverride,
      size: size,
    );
  }
}
