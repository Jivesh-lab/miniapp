import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../utils/checks.dart';
import 'network_service.dart';
import '../../models/service_item.dart';
import 'api_exception.dart';
import 'socket_service.dart';

class AppApiClient {
  static Duration get requestTimeout {
    return ApiConfig.isProduction
        ? const Duration(seconds: 30)
        : const Duration(seconds: 12);
  }

  static const int _maxRetries = 2;
  static const String _legacyTokenKey = 'auth_token';
  static const String _userTokenKey = 'user_token';
  static const String _workerSessionKey = 'worker_session';

  static Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  static String? _extractWorkerToken(String? rawSession) {
    if (rawSession == null || rawSession.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawSession);
      if (decoded is Map<String, dynamic>) {
        final token = (decoded['token'] ?? '').toString();
        if (token.isNotEmpty) {
          return token;
        }
      }
    } catch (_) {
      // Ignore malformed session payload.
    }

    return null;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final userToken = prefs.getString(_userTokenKey);
    if (userToken != null && userToken.isNotEmpty) {
      return userToken;
    }

    final legacyToken = prefs.getString(_legacyTokenKey);
    if (legacyToken != null && legacyToken.isNotEmpty) {
      return legacyToken;
    }

    return _extractWorkerToken(prefs.getString(_workerSessionKey));
  }

  static Future<bool> hasSavedSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_legacyTokenKey, token);
    await prefs.setString(_userTokenKey, token);
    SocketService().initSocket();
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyTokenKey);
    await prefs.remove(_userTokenKey);
    await prefs.remove('user_id');
    await prefs.remove(_workerSessionKey);
    await prefs.remove('cached_profile');
    SocketService().disconnect();
  }

  static Future<Map<String, String>> _headers({bool withAuth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (withAuth) {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        throw const ApiException(message: 'No token, unauthorized', statusCode: 401);
      }
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() request,
  ) async {
    final hasInternet = await ConnectivityService.checkConnected();
    if (!hasInternet) {
      throw const ApiException(
        message: 'Please check your internet connection',
        statusCode: 0,
      );
    }
    var attempt = 0;

    while (true) {
      try {
        return await request().timeout(requestTimeout);
      } on TimeoutException {
        if (attempt >= _maxRetries) {
          throw const ApiException(
            message: 'Network timeout. Please try again.',
            statusCode: 408,
          );
        }
      } on SocketException {
        if (attempt >= _maxRetries) {
          throw const ApiException(
            message: 'Network error. Please check your connection.',
            statusCode: 0,
          );
        }
      }

      attempt += 1;
      await Future.delayed(Duration(seconds: attempt));
    }
  }

  static Map<String, dynamic> _decodeBody(http.Response response) {
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Fall through to generic error.
    }

    throw ApiException(
      message: 'Unexpected response from server',
      statusCode: response.statusCode,
    );
  }

  static Future<void> _throwIfError(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final body = _decodeBody(response);
    if (response.statusCode == 401 || response.statusCode == 403) {
      await clearSession();
    }

    throw ApiException(
      message: body['message']?.toString() ?? 'Request failed',
      statusCode: response.statusCode,
    );
  }

  static Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _executeWithRetry(
      () => http.post(
        _uri('/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier,
          'password': password,
        }),
      ),
    );

    await _throwIfError(response);

    final body = _decodeBody(response);
    final token = (body['token'] ?? (body['data'] as Map<String, dynamic>?)?['token'] ?? '').toString();
    if (token.isNotEmpty) {
      await saveToken(token);
    }

    return body;
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _executeWithRetry(
      () => http.post(
        _uri('/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      ),
    );

    await _throwIfError(response);
    return _decodeBody(response);
  }

  static Future<List<ServiceItem>> getServices() async {
    final response = await _executeWithRetry(
      () => http.get(
        _uri('/services'),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    await _throwIfError(response);

    final body = _decodeBody(response);
    final rawServices = (body['data'] as List<dynamic>? ?? <dynamic>[]);
    return rawServices
        .whereType<Map<String, dynamic>>()
        .map(ServiceItem.fromJson)
        .where((service) => service.name.isNotEmpty)
        .toList(growable: false);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await _executeWithRetry(
      () async => http.get(
        _uri('/profile'),
        headers: await _headers(withAuth: true),
      ),
    );

    await _throwIfError(response);

    final body = _decodeBody(response);
    final profile = body['data'];
    if (profile is Map<String, dynamic>) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_profile', jsonEncode(profile));
      return profile;
    }

    return <String, dynamic>{};
  }

  static Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        await _executeWithRetry(
          () => http.post(
            _uri('/auth/logout'),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
            body: jsonEncode(<String, dynamic>{}),
          ),
        );
      }
    } catch (_) {
      // Best effort logout; local session is cleared below.
    }

    await clearSession();
  }
}

