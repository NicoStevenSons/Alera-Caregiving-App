import 'package:flutter/services.dart';

/// Plays a bundled sound for the settings screen.
abstract interface class NotificationSoundPreview {
  /// Plays the bundled `res/raw` sound [resource]; false if it could not play.
  Future<bool> playResource(String resource);
  Future<void> stop();

  /// Opens the Android system settings page for [channelId], where the user
  /// can allow it to override Do Not Disturb. False if it could not open.
  Future<bool> openChannelSettings(String channelId);
}

class PlatformNotificationSoundPreview implements NotificationSoundPreview {
  const PlatformNotificationSoundPreview();

  static const MethodChannel _channel = MethodChannel(
    'com.alera.payloadextraction/notification_sounds',
  );

  @override
  Future<bool> playResource(String resource) async {
    try {
      return await _channel.invokeMethod<bool>('preview', {
            'resource': resource,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      // Not on Android (tests, desktop): nothing to stop.
    } on PlatformException {
      // Ignore.
    }
  }

  @override
  Future<bool> openChannelSettings(String channelId) async {
    try {
      return await _channel.invokeMethod<bool>('openChannelSettings', {
            'channelId': channelId,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
