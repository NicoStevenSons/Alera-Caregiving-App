/// SVG asset paths for status glyphs.
///
/// Every path here is asserted to exist on disk and to parse by
/// `test/design_system/status/alera_status_assets_test.dart`, so a missing or
/// malformed asset fails CI rather than throwing at runtime in front of a
/// caregiver.
abstract final class AleraStatusAssets {
  static const String _deviceStatus =
      'alera-figma-assets/assets/icons/device_status';

  /// Low battery. Figma-authored asset.
  static const String deviceLowBattery = '$_deviceStatus/batterylvl-low.svg';

  /// Every declared SVG path, for the asset-existence test.
  static const List<String> all = <String>[deviceLowBattery];
}
