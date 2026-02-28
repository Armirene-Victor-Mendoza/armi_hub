import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _baseUrlFromDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  const ApiConfig({required this.baseUrl});

  final String baseUrl;

  factory ApiConfig.fromEnvironment() {
    if (_baseUrlFromDefine.isNotEmpty) {
      return ApiConfig(baseUrl: _baseUrlFromDefine);
    }

    if (kReleaseMode) {
      return const ApiConfig(baseUrl: 'https://api.example.com');
    }

    if (Platform.isAndroid) {
      return const ApiConfig(baseUrl: 'http://10.0.2.2:3000');
    }

    if (Platform.isIOS) {
      return const ApiConfig(baseUrl: 'http://localhost:3000');
    }

    return const ApiConfig(baseUrl: 'http://localhost:3000');
  }
}
