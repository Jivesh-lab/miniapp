import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/api_service.dart' as shared_api;
import '../core/services/api_exception.dart';
import '../models/booking_model.dart';

class WorkerSession {
  final String workerId;
  final String token;

  const WorkerSession({
    required this.workerId,
    required this.token,
  });

  Map<String, dynamic> toJson() {
    return {
      'workerId': workerId,
      'token': token,
    };
  }

  factory WorkerSession.fromJson(Map<String, dynamic> json) {
    return WorkerSession(
      workerId: (json['workerId'] ?? '').toString(),
      token: (json['token'] ?? '').toString(),
    );
  }
}

class WorkerApiService {
  static const String _baseUrl = 'http://192.168.0.105:3000/api';
  static const String _sessionKey = 'worker_session';

  final Duration _cacheTtl = const Duration(seconds: 30);
  List<WorkerBooking>? _cachedBookings;
  DateTime? _lastBookingsFetchAt;

  Future<WorkerSession> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await _postJson(
        '$_baseUrl/auth/login',
        {
          'identifier': identifier.trim(),
          'password': password,
        },
      );

      final body = _parseResponse(response);
      final data = (body['data'] as Map<String, dynamic>? ?? <String, dynamic>{});
      final role = (body['role'] ?? data['role'] ?? '').toString().toLowerCase();

      if (role != 'worker') {
        throw const ApiException(
          message: 'Please sign in with a worker account',
          statusCode: 403,
        );
      }

      final workerId = (body['id'] ?? data['workerId'] ?? data['id'] ?? data['_id'] ?? '').toString();
      final token = (body['token'] ?? data['token'] ?? '').toString();

      if (workerId.isEmpty || token.isEmpty) {
        throw const ApiException(
          message: 'Invalid login response from server',
          statusCode: 500,
        );
      }

      final session = WorkerSession(workerId: workerId, token: token);
      await saveSession(session);
      return session;
    } catch (error) {
      if (error is ApiException) {
        rethrow;
      }
      rethrow;
    }
  }

  Future<List<WorkerBooking>> getWorkerBookings({
    required WorkerSession session,
    bool forceRefresh = false,
  }) async {
    try {
      final now = DateTime.now();

      if (!forceRefresh &&
          _cachedBookings != null &&
          _lastBookingsFetchAt != null &&
          now.difference(_lastBookingsFetchAt!) < _cacheTtl) {
        return List<WorkerBooking>.from(_cachedBookings!);
      }

      final response = await _getJson(
        '$_baseUrl/workers/bookings',
        token: session.token,
      );

      final body = await _parseAuthenticatedResponse(
        response,
        loginRoute: '/worker/login',
        clearSession: clearSession,
      );
      final data = (body['data'] as List<dynamic>? ?? <dynamic>[])
          .cast<Map<String, dynamic>>();

      final bookings = data.map(WorkerBooking.fromJson).toList();
      _cachedBookings = bookings;
      _lastBookingsFetchAt = now;

      return List<WorkerBooking>.from(bookings);
    } catch (error) {
      if (error is ApiException) {
        rethrow;
      }
      rethrow;
    }
  }

  Future<WorkerBooking> updateBookingStatus({
    required WorkerSession session,
    required String bookingId,
    required String status,
  }) async {
    try {
      final response = await _patchJson(
        '$_baseUrl/bookings/$bookingId',
        {
          'status': status,
        },
        token: session.token,
      );

      final body = await _parseAuthenticatedResponse(
        response,
        loginRoute: '/worker/login',
        clearSession: clearSession,
      );
      final data = (body['data'] as Map<String, dynamic>? ?? <String, dynamic>{});

      _cachedBookings = null;
      _lastBookingsFetchAt = null;

      return WorkerBooking.fromJson(data);
    } catch (error) {
      if (error is ApiException) {
        rethrow;
      }
      rethrow;
    }
  }

  Future<void> saveSession(WorkerSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<WorkerSession?> getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);

    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final session = WorkerSession.fromJson(json);

      if (session.workerId.isEmpty || session.token.isEmpty) {
        return null;
      }

      return session;
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _cachedBookings = null;
    _lastBookingsFetchAt = null;
  }

  Future<void> logout() async {
    final session = await getSavedSession();

    if (session != null) {
      try {
        await _postJson(
          '$_baseUrl/auth/logout',
          <String, dynamic>{},
          token: session.token,
        );
      } catch (_) {
        // Best effort logout; local session is cleared below.
      }
    }

    await clearSession();
  }

  Future<Map<String, dynamic>> getWorkerProfile() async {
    try {
      final session = await getSavedSession();

      if (session == null) {
        throw const ApiException(message: 'Please login again', statusCode: 401);
      }

      final response = await _getJson(
        '$_baseUrl/workers/profile',
        token: session.token,
      );

      final body = await _parseAuthenticatedResponse(
        response,
        loginRoute: '/worker/login',
        clearSession: clearSession,
      );

      return (body['data'] as Map<String, dynamic>? ?? <String, dynamic>{});
    } catch (error) {
      if (error is ApiException) {
        rethrow;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateWorkerProfile({
    required Object serviceId,
    required Object price,
    required String location,
    required List<String> skills,
  }) async {
    try {
      final session = await getSavedSession();

      if (session == null) {
        throw const ApiException(message: 'Please login again', statusCode: 401);
      }

      final response = await _putJson(
        '$_baseUrl/workers/profile',
        {
          'serviceId': serviceId,
          'price': price,
          'location': location,
          'skills': skills,
        },
        token: session.token,
      );

      final body = await _parseAuthenticatedResponse(
        response,
        loginRoute: '/worker/login',
        clearSession: clearSession,
      );

      return (body['data'] as Map<String, dynamic>? ?? <String, dynamic>{});
    } catch (error) {
      if (error is ApiException) {
        rethrow;
      }
      rethrow;
    }
  }

  Future<http.Response> _getJson(String url, {required String token}) {
    return _send(
      'get',
      Uri.parse(url),
      token: token,
    );
  }

  Future<http.Response> _postJson(
    String url,
    Map<String, dynamic> payload, {
    String? token,
  }) {
    return _send('post', Uri.parse(url), body: payload, token: token);
  }

  Future<http.Response> _putJson(
    String url,
    Map<String, dynamic> payload, {
    String? token,
  }) {
    return _send('put', Uri.parse(url), body: payload, token: token);
  }

  Future<http.Response> _patchJson(
    String url,
    Map<String, dynamic> payload, {
    String? token,
  }) {
    return _send('patch', Uri.parse(url), body: payload, token: token);
  }

  Future<http.Response> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      late final http.Response response;
      switch (method) {
        case 'get':
          response = await http.get(uri, headers: headers).timeout(shared_api.ApiService.requestTimeout);
          break;
        case 'post':
          response = await http
              .post(uri, headers: headers, body: jsonEncode(body ?? <String, dynamic>{}))
              .timeout(shared_api.ApiService.requestTimeout);
          break;
        case 'put':
          response = await http
              .put(uri, headers: headers, body: jsonEncode(body ?? <String, dynamic>{}))
              .timeout(shared_api.ApiService.requestTimeout);
          break;
        case 'patch':
          response = await http
              .patch(uri, headers: headers, body: jsonEncode(body ?? <String, dynamic>{}))
              .timeout(shared_api.ApiService.requestTimeout);
          break;
        default:
          throw const ApiException(message: 'Unsupported request method', statusCode: 500);
      }

      return response;
    } on TimeoutException {
      throw const ApiException(message: 'Network timeout, please try again', statusCode: 408);
    } on SocketException {
      throw const ApiException(message: 'Network error, please check your connection', statusCode: 503);
    }
  }

  Future<Map<String, dynamic>> _parseAuthenticatedResponse(
    http.Response response, {
    required String loginRoute,
    required Future<void> Function() clearSession,
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

  Map<String, dynamic> _parseResponse(http.Response response) {
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

    throw ApiException(
      message: body['message']?.toString() ?? 'Request failed',
      statusCode: response.statusCode,
    );
  }
}
