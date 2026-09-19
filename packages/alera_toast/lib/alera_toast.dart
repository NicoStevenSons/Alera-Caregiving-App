import 'package:flutter/services.dart';

const MethodChannel _aleraNativeChannel = MethodChannel('com.alera/toast');

/// Displays short, system-styled feedback without opening the app.
class AleraToast {
  AleraToast._();

  static Future<void> show(String message) => _aleraNativeChannel
      .invokeMethod<void>('show', <String, String>{'message': message});
}

/// Builds the Android notification large icon in native code so it also works
/// from Firebase Messaging's background isolate.
class AleraNotificationAvatar {
  AleraNotificationAvatar._();

  static Future<Uint8List?> render({
    required String patientName,
    required String metricType,
    Uint8List? photoBytes,
  }) {
    return _aleraNativeChannel
        .invokeMethod<Uint8List>('renderNotificationAvatar', <String, Object?>{
          'patient_name': patientName,
          'metric_type': metricType,
          'photo_bytes': ?photoBytes,
        });
  }
}
