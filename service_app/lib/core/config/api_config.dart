import 'package:flutter/foundation.dart';

class ApiConfig {
  // ============================================
  // 🌍 ENVIRONMENT URLS
  // ============================================
  
  // Local development (your existing IP)
  static const String _localBaseUrl = 'http://192.168.0.104:3000';
  
  // Production (Render)
  static const String _productionBaseUrl = 'https://miniapp-euip.onrender.com';
  
  // ============================================
  // ⚙️ CONFIGURATION
  // ============================================
  
  // 🟢 AUTO-DETECT: Debug mode = Local, Release mode = Production
  // NO NEED TO CHANGE! Just build APK and it will automatically use Render.
  static bool get isProduction {
    return !kDebugMode;  // true if APK (release), false if running locally (debug)
  }
  
  // ============================================
  // EXISTING OVERRIDE MECHANISM (unchanged)
  // ============================================
  
  static const String _overrideApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _overrideSocketBaseUrl = String.fromEnvironment(
    'SOCKET_BASE_URL',
    defaultValue: '',
  );

  // ============================================
  // 📡 GET SOCKET URL
  // ============================================
  
  static String get socketUrl {
    if (_overrideSocketBaseUrl.isNotEmpty) {
      return _normalizeBase(_overrideSocketBaseUrl);
    }

    if (isProduction) {
      return _normalizeBase(_productionBaseUrl);
    }

    if (kIsWeb) {
      return _normalizeBase(_localBaseUrl);
    }

    return _normalizeBase(_localBaseUrl);
  }

  // ============================================
  // 🔗 GET API BASE URL (main getter)
  // ============================================
  
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

  // ============================================
  // 🛠️ HELPER METHODS
  // ============================================
  
  static String _normalizeBase(String url) {
    var normalized = url.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  // Get current environment name for debugging
  static String get environment {
    if (_overrideApiBaseUrl.isNotEmpty) {
      return 'Override: $_overrideApiBaseUrl';
    }
    return isProduction ? 'Production (Render APK)' : 'Local Development (Debug)';
  }
}