import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'api_exception.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;
  
  // ============================================
  // ⏱️ TIMEOUT CONFIGURATION FOR RENDER
  // ============================================
  // Increased timeout for Render cold start (30 seconds for production, 15 for local)
  static Duration get requestTimeout {
    return ApiConfig.isProduction 
        ? const Duration(seconds: 30)  // Production: 30s for Render
        : const Duration(seconds: 15); // Local: 15s
  }
  
  // ============================================
  // 🔄 RETRY CONFIGURATION
  // ============================================
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(milliseconds: 500);
  
  static const String _legacyAuthTokenKey = 'auth_token';
  static const String _userTokenKey = 'user_token';
  static const String _userIdKey = 'user_id';
  static const String _workerSessionKey = 'worker_session';

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
      // Ignore invalid session payload and fall back to unauthenticated headers.
    }

    return null;
  }

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
      };

  static Future<Map<String, String>> authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final userToken = prefs.getString(_userTokenKey);
    final legacyToken = prefs.getString(_legacyAuthTokenKey);
    final workerToken = _extractWorkerToken(prefs.getString(_workerSessionKey));
    final token = (userToken != null && userToken.isNotEmpty)
        ? userToken
        : ((legacyToken != null && legacyToken.isNotEmpty) ? legacyToken : workerToken);

    final map = <String, String>{
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      map['Authorization'] = 'Bearer $token';
    }

    return map;
  }

  // ============================================
  // 🔄 INTELLIGENT RETRY LOGIC FOR RENDER COLD START
  // ============================================
  
  static Future<T> _retryRequest<T>(
    Future<T> Function() request, {
    int retryCount = 0,
  }) async {
    try {
      return await request();
    } on TimeoutException catch (e) {
      if (retryCount < maxRetries) {
        final waitTime = retryDelay * (retryCount + 1); // Exponential backoff
        print('⏳ Request timeout, retrying... (${retryCount + 1}/$maxRetries) after ${waitTime.inSeconds}s');
        await Future.delayed(waitTime);
        return _retryRequest(request, retryCount: retryCount + 1);
      }
      rethrow;
    } on SocketException catch (e) {
      if (retryCount < maxRetries) {
        final waitTime = retryDelay * (retryCount + 1); // Exponential backoff
        print('🔗 Network error, retrying... (${retryCount + 1}/$maxRetries) after ${waitTime.inSeconds}s');
        await Future.delayed(waitTime);
        return _retryRequest(request, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }
  
  // ============================================
  // 🚀 HEALTH CHECK TO WARM UP RENDER SERVER
  // ============================================
  static Future<bool> warmUpServer() async {
    try {
      print('🚀 Warming up server at ${ApiConfig.socketUrl}...');
      await _retryRequest(() async {
        return await http
            .get(Uri.parse('${ApiConfig.socketUrl}/ping'))
            .timeout(const Duration(seconds: 5));
      });
      print('✅ Server is ready');
      return true;
    } catch (e) {
      print('⚠️  Server warmup failed (non-blocking): $e');
      return false; // Don't block app, continue anyway
    }
  }

  static Future<void> saveUserSession({required String token, required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userTokenKey, token);
    // Backward compatibility for screens still reading auth_token.
    await prefs.setString(_legacyAuthTokenKey, token);
    await prefs.setString(_userIdKey, userId);
  }

  static Future<void> saveWorkerSession({required String token, required String workerId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _workerSessionKey,
      jsonEncode({
        'workerId': workerId,
        'token': token,
      }),
    );
  }

  static Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userTokenKey);
    await prefs.remove(_legacyAuthTokenKey);
    await prefs.remove(_userIdKey);
  }

  static Future<void> clearWorkerSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_workerSessionKey);
  }

  static Future<void> clearAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userTokenKey);
    await prefs.remove(_legacyAuthTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_workerSessionKey);
  }

  static Future<String?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Uri uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  static Map<String, dynamic> parseResponse(http.Response response) {
    final Map<String, dynamic> body;

    try {
      body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        message: 'Unexpected response from server',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw ApiException(
      message: body['message']?.toString() ?? 'Request failed',
      statusCode: response.statusCode,
    );
  }

  static Future<Map<String, dynamic>> parseAuthenticatedResponse(
    http.Response response, {
    required Future<void> Function() clearSession,
    required String loginRoute,
  }) async {
    final Map<String, dynamic> body;

    try {
      body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const ApiException(
        message: 'Unexpected response from server',
        statusCode: 500,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    if (response.statusCode == 401) {
      throw ApiException(
        message: body['message']?.toString() ?? 'Session expired or invalid token',
        statusCode: 401,
      );
    }

    throw ApiException(
      message: body['message']?.toString() ?? 'Request failed',
      statusCode: response.statusCode,
    );
  }

  static Future<Map<String, dynamic>> loginByRole({
    required String role,
    required String identifier,
    required String password,
  }) async {
    final normalizedRole = role.toLowerCase();

    if (normalizedRole != 'user' && normalizedRole != 'worker') {
      throw const ApiException(message: 'Invalid role selected', statusCode: 400);
    }

    final response = await postJson('/auth/login', {
      'identifier': identifier.trim(),
      'password': password,
    });

    final parsed = parseResponse(response);

    if (parsed['otpRequired'] == true) {
      return parsed;
    }

    final data = (parsed['data'] as Map<String, dynamic>? ?? <String, dynamic>{});
    final responseRole = (parsed['role'] ?? data['role'] ?? normalizedRole).toString().toLowerCase();
    final token = (parsed['token'] ?? data['token'] ?? '').toString();
    final id = (parsed['id'] ?? data['id'] ?? data['_id'] ?? '').toString();
    final name = (parsed['name'] ?? data['name'] ?? '').toString();
    final email = (parsed['email'] ?? data['email'] ?? '').toString();
    final phone = (parsed['phone'] ?? data['phone'] ?? '').toString();

    if (responseRole == 'worker') {
      if (token.isNotEmpty && id.isNotEmpty) {
        await saveWorkerSession(token: token, workerId: id);
      }
    } else if (responseRole == 'user') {
      if (token.isNotEmpty && id.isNotEmpty) {
        await saveUserSession(token: token, userId: id);
        // Save user name and other data locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', name);
        await prefs.setString('user_email', email);
        await prefs.setString('user_phone', phone);
      }
    }

    return parsed;
  }

  static Future<Map<String, dynamic>> verifyLoginOtp({
    required String tempToken,
    required String otp,
    required String role,
  }) async {
    final response = await postJson('/auth/verify-login-otp', {
      'identifier': tempToken,
      'otp': otp.trim(),
      'role': role,
    });

    final parsed = parseResponse(response);
    final data = (parsed['data'] as Map<String, dynamic>? ?? <String, dynamic>{});
    final responseRole = (parsed['role'] ?? data['role'] ?? '').toString().toLowerCase();
    final token = (parsed['token'] ?? data['token'] ?? '').toString();
    final id = (parsed['id'] ?? data['id'] ?? data['_id'] ?? '').toString();

    if (responseRole == 'worker') {
      if (token.isNotEmpty && id.isNotEmpty) {
        await saveWorkerSession(token: token, workerId: id);
      }
    } else if (responseRole == 'user') {
      if (token.isNotEmpty && id.isNotEmpty) {
        await saveUserSession(token: token, userId: id);
      }
    }

    return parsed;
  }

  static Future<void> logoutUser() async {
    try {
      await postJson('/auth/logout', <String, dynamic>{}, useAuthHeaders: true);
    } catch (_) {
      // Best effort. Local session is always cleared below.
    }

    await clearUserSession();
  }

  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String phone,
    required String password,
    required String email,
  }) async {
    final response = await postJson('/auth/register-user', {
      'name': name.trim(),
      'phone': phone.trim(),
      'password': password,
      'email': email.trim(),
    });

    return parseResponse(response);
  }

  static Future<Map<String, dynamic>> registerWorker({
    required String name,
    required String phone,
    required String password,
  }) async {
    final response = await postJson('/auth/register-worker', {
      'name': name.trim(),
      'phone': phone.trim(),
      'password': password,
    });

    return parseResponse(response);
  }

  // ============================================
  // 🔗 HTTP METHODS WITH AUTOMATIC RETRY
  // ============================================

  static Future<http.Response> postJson(
    String path,
    Map<String, dynamic> payload, {
    bool useAuthHeaders = false,
  }) async {
    return _retryRequest(() async {
      try {
        return await http
            .post(
              uri(path),
              headers: useAuthHeaders ? await authHeaders() : headers,
              body: jsonEncode(payload),
            )
            .timeout(requestTimeout);
      } on TimeoutException {
        throw const ApiException(message: 'Network timeout, please try again', statusCode: 408);
      } on SocketException {
        throw const ApiException(message: 'Network error, please check your connection', statusCode: 0);
      }
    });
  }

  static Future<http.Response> getJson(
    String path, {
    Map<String, String>? query,
    bool useAuthHeaders = false,
  }) async {
    return _retryRequest(() async {
      try {
        return await http
            .get(
              uri(path, query),
              headers: useAuthHeaders ? await authHeaders() : headers,
            )
            .timeout(requestTimeout);
      } on TimeoutException {
        throw const ApiException(message: 'Network timeout, please try again', statusCode: 408);
      } on SocketException {
        throw const ApiException(message: 'Network error, please check your connection', statusCode: 0);
      }
    });
  }

  static Future<http.Response> putJson(
    String path,
    Map<String, dynamic> payload, {
    bool useAuthHeaders = false,
  }) async {
    return _retryRequest(() async {
      try {
        return await http
            .put(
              uri(path),
              headers: useAuthHeaders ? await authHeaders() : headers,
              body: jsonEncode(payload),
            )
            .timeout(requestTimeout);
      } on TimeoutException {
        throw const ApiException(message: 'Network timeout, please try again', statusCode: 408);
      } on SocketException {
        throw const ApiException(message: 'Network error, please check your connection', statusCode: 0);
      }
    });
  }

  static Future<http.Response> patchJson(
    String path,
    Map<String, dynamic> payload, {
    bool useAuthHeaders = false,
  }) async {
    return _retryRequest(() async {
      try {
        return await http
            .patch(
              uri(path),
              headers: useAuthHeaders ? await authHeaders() : headers,
              body: jsonEncode(payload),
            )
            .timeout(requestTimeout);
      } on TimeoutException {
        throw const ApiException(message: 'Network timeout, please try again', statusCode: 408);
      } on SocketException {
        throw const ApiException(message: 'Network error, please check your connection', statusCode: 0);
      }
    });
  }
}
