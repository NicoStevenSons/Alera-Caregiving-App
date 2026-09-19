import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class HealthEventApiService {
  final String baseUrl;
  final String patientId;

  const HealthEventApiService({required this.baseUrl, required this.patientId});

  Future<http.Response> sendHealthEvent(Map<String, dynamic> payload) async {
    final Uri endpoint = Uri.parse('$baseUrl/api/v1/health-events');

    debugPrint(
      'Sending backend payload: '
      '${jsonEncode(payload)}',
    );

    final http.Response response = await http
        .post(
          endpoint,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    debugPrint(
      'Backend response: '
      '${response.statusCode} ${response.body}',
    );

    return response;
  }
}
