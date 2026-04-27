import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _overrideApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _overrideSocketBaseUrl = String.fromEnvironment(
    'SOCKET_BASE_URL',
    defaultValue: '',
  );

  // Web runs from localhost, so default to local backend unless overridden.
  static String get socketUrl {
    if (_overrideSocketBaseUrl.isNotEmpty) {
      return _normalizeBase(_overrideSocketBaseUrl);
    }

    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    return 'http://192.168.0.104:3000';
  }

  static String get baseUrl {
    if (_overrideApiBaseUrl.isNotEmpty) {
      final normalized = _normalizeBase(_overrideApiBaseUrl);
      if (normalized.endsWith('/api')) {
        return normalized;
      }
      return '$normalized/api';
    }

    return '$socketUrl/api';
  }

  static String _normalizeBase(String url) {
    var normalized = url.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}