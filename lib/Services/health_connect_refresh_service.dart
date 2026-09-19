import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class HealthConnectRefreshService {
  static const MethodChannel _channel = MethodChannel(
    'com.alera.payloadextraction/health_refresh',
  );

  Future<bool> refreshSteps() async {
    try {
      final bool? refreshed =
          await _channel.invokeMethod<bool>(
        'refreshSteps',
      );

      debugPrint(
        'Health Connect steps refresh completed: '
        '${refreshed == true}',
      );

      return refreshed == true;
    } on PlatformException catch (error) {
      debugPrint(
        'Health Connect steps refresh failed: '
        '${error.code} ${error.message}',
      );

      return false;
    } catch (error) {
      debugPrint(
        'Unexpected steps refresh error: $error',
      );

      return false;
    }
  }

  Future<bool> refreshSleep() async {
    try {
      final bool? refreshed =
          await _channel.invokeMethod<bool>(
        'refreshSleep',
      );

      debugPrint(
        'Health Connect sleep refresh completed: '
        '${refreshed == true}',
      );

      return refreshed == true;
    } on PlatformException catch (error) {
      debugPrint(
        'Health Connect sleep refresh failed: '
        '${error.code} ${error.message}',
      );

      return false;
    } catch (error) {
      debugPrint(
        'Unexpected sleep refresh error: $error',
      );

      return false;
    }
  }
}