import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'api_exception.dart';
import '../../models/service_item.dart';

class AppApiClient {
  static const Duration requestTimeout = Duration(seconds: 12);
  static const String _tokenKey = 'auth_token';

  static Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  static Future<bool> hasSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove('cached_profile');
  }

  static Future<Map<String, String>> _headers({bool withAuth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (withAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
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
      // Fall through to the generic error below.
    }

    throw ApiException(
      message: 'Unexpected response from server',
      statusCode: response.statusCode,
    );
  }

  static void _throwIfError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final body = _decodeBody(response);
    throw ApiException(
      message: body['message']?.toString() ?? 'Request failed',
      statusCode: response.statusCode,
    );
  }

  static Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final response = await http
        .post(
          _uri('/login'),
          headers: await _headers(),
          body: jsonEncode({
            'identifier': identifier,
            'password': password,
          }),
        )
        .timeout(requestTimeout);

    _throwIfError(response);

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
    final response = await http
        .post(
          _uri('/register'),
          headers: await _headers(),
          body: jsonEncode({
            'name': name,
            'email': email,
            'phone': phone,
            'password': password,
          }),
        )
        .timeout(requestTimeout);

    _throwIfError(response);
    return _decodeBody(response);
  }

  static Future<List<ServiceItem>> getServices() async {
    final response = await http
        .get(
          _uri('/services'),
          headers: await _headers(),
        )
        .timeout(requestTimeout);

    _throwIfError(response);

    final body = _decodeBody(response);
    final rawServices = (body['data'] as List<dynamic>? ?? <dynamic>[]);
    return rawServices
        .whereType<Map<String, dynamic>>()
        .map(ServiceItem.fromJson)
        .where((service) => service.name.isNotEmpty)
        .toList(growable: false);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http
        .get(
          _uri('/profile'),
          headers: await _headers(withAuth: true),
        )
        .timeout(requestTimeout);

    _throwIfError(response);

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
      // Best effort logout API call
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        await http
            .post(
              _uri('/auth/logout'),
              headers: await _headers(withAuth: true),
              body: jsonEncode(<String, dynamic>{}),
            )
            .timeout(requestTimeout);
      }
    } catch (_) {
      // Best effort logout; local session is cleared below
    }
    
    await clearSession();
  }
}