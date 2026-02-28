import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiResponse {
  const ApiResponse({required this.statusCode, required this.bodyRaw});

  final int statusCode;
  final String bodyRaw;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => 'ApiException($message)';
}

class ApiClient {
  ApiClient({required this.config, http.Client? client}) : _client = client ?? http.Client();

  final ApiConfig config;
  final http.Client _client;

  Future<ApiResponse> postJson(
    String path,
    Map<String, dynamic> payload, {
    Duration timeout = const Duration(seconds: 20),
    Map<String, String> extraHeaders = const {},
  }) async {
    final uri = Uri.parse('${config.baseUrl}$path');

    try {
      final response = await _client
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              ...extraHeaders,
            },
            body: jsonEncode(payload),
          )
          .timeout(timeout);

      return ApiResponse(statusCode: response.statusCode, bodyRaw: response.body);
    } on TimeoutException {
      throw const ApiException('La solicitud excedio el tiempo de espera.');
    } catch (error) {
      throw ApiException('Error de red enviando solicitud: $error');
    }
  }

  void close() {
    _client.close();
  }
}
