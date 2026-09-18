import 'package:flutter/services.dart';

/// Displays short, system-styled feedback without opening the app.
class AleraToast {
  AleraToast._();

  static const _channel = MethodChannel('com.alera/toast');

  static Future<void> show(String message) =>
      _channel.invokeMethod<void>('show', <String, String>{'message': message});
}
