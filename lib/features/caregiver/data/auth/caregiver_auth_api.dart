import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../config/app_config.dart';

class CaregiverAuthApi {
  final http.Client _client;
  final Duration timeout;

  CaregiverAuthApi({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  Future<HouseholdValidationResult> validateHousehold({
    required String householdCode,
  }) async {
    final uri = Uri.parse(
      '${AppConfig.backendBaseUrl}/api/v1/auth/household/validate',
    );
    try {
      final response = await _client
          .post(
            uri,
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({'household_code': householdCode}),
          )
          .timeout(timeout);
      if (response.statusCode == 404) {
        throw const HouseholdNotFoundFailure();
      }
      if (response.statusCode != 200) {
        throw const HouseholdValidationFailure();
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['valid'] != true) {
        throw const HouseholdNotFoundFailure();
      }
      final householdName = decoded['household_name'];
      if (householdName is! String || householdName.trim().isEmpty) {
        throw const HouseholdValidationFailure();
      }
      return HouseholdValidationResult(householdName.trim());
    } on TimeoutException {
      throw const HouseholdValidationFailure();
    } on HouseholdValidationException {
      rethrow;
    } on http.ClientException {
      throw const HouseholdValidationFailure();
    } on FormatException {
      throw const HouseholdValidationFailure();
    }
  }

  Future<String> login({
    required String householdCode,
    required String email,
    required String password,
  }) async {
    final Uri uri = Uri.parse(
      '${AppConfig.backendBaseUrl}/api/v1/auth/caregiver/login',
    );
    try {
      final http.Response response = await _client
          .post(
            uri,
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'household_code': householdCode,
              'email': email,
              'password': password,
            }),
          )
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (kDebugMode) {
          debugPrint('Caregiver login: HTTP ${response.statusCode} from $uri.');
        }
        throw CaregiverLoginFailure('Unable to sign in. Check your details.');
      }
      try {
        final Object? decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Response must be a JSON object.');
        }
        final Object? accessToken = decoded['access_token'];
        final Object? tokenType = decoded['token_type'];
        if (accessToken is! String || accessToken.trim().isEmpty) {
          throw const FormatException('Missing bearer access token.');
        }
        // The deployed response model defaults token_type to "bearer", so
        // FastAPI may omit it while still returning a valid login response.
        if (tokenType != null &&
            (tokenType is! String || tokenType.toLowerCase() != 'bearer')) {
          throw const FormatException('Unsupported token type.');
        }
        return accessToken;
      } on FormatException catch (error, stackTrace) {
        _debugLoginFailure(
          'Invalid HTTP 200 login response. Keys: '
          '${_responseKeys(response.body)}',
          error,
          stackTrace,
        );
        throw CaregiverLoginFailure('Unable to sign in. Please try again.');
      }
    } on TimeoutException catch (error, stackTrace) {
      _debugLoginFailure('Login request timed out.', error, stackTrace);
      throw CaregiverLoginFailure('Unable to connect. Please try again.');
    } on CaregiverLoginFailure {
      rethrow;
    } on http.ClientException catch (error, stackTrace) {
      _debugLoginFailure('Login network request failed.', error, stackTrace);
      throw CaregiverLoginFailure('Unable to connect. Please try again.');
    }
  }
}

List<String> _responseKeys(String responseBody) {
  try {
    final Object? decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) {
      return decoded.keys.toList(growable: false);
    }
  } catch (_) {
    // The parsing exception is logged by the caller without response values.
  }
  return const [];
}

void _debugLoginFailure(String context, Object error, StackTrace stackTrace) {
  if (!kDebugMode) return;
  debugPrint('Caregiver login: $context');
  debugPrint('$error');
  debugPrintStack(stackTrace: stackTrace);
}

class CaregiverLoginFailure implements Exception {
  final String message;

  const CaregiverLoginFailure(this.message);
}

class HouseholdValidationResult {
  final String householdName;
  const HouseholdValidationResult(this.householdName);
}

sealed class HouseholdValidationException implements Exception {
  final String message;
  const HouseholdValidationException(this.message);
}

class HouseholdNotFoundFailure extends HouseholdValidationException {
  const HouseholdNotFoundFailure()
    : super(
        'We couldn’t find that household code. Check the code and try again.',
      );
}

class HouseholdValidationFailure extends HouseholdValidationException {
  const HouseholdValidationFailure()
    : super(
        'We couldn’t verify the household right now. Check your connection and try again.',
      );
}
