import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/worker_model.dart';
import 'api_service.dart';

class UserService {
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await ApiService.getJson('/users/profile', useAuthHeaders: true);
      final body = await ApiService.parseAuthenticatedResponse(
        response,
        clearSession: ApiService.clearUserSession,
        loginRoute: '/login',
      );

      return (body['data'] as Map<String, dynamic>? ?? <String, dynamic>{});
    } catch (error) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    required String name,
    required String phone,
  }) async {
    try {
      final response = await ApiService.putJson(
        '/users/$userId',
        {
          'name': name.trim(),
          'phone': phone.trim(),
        },
        useAuthHeaders: true,
      );

      final body = await ApiService.parseAuthenticatedResponse(
        response,
        clearSession: ApiService.clearUserSession,
        loginRoute: '/login',
      );

      return (body['data'] as Map<String, dynamic>? ?? <String, dynamic>{});
    } catch (error) {
      rethrow;
    }
  }

  Future<bool> toggleFavorite({
    required String userId,
    required String workerId,
  }) async {
    try {
      final response = await ApiService.postJson(
        '/users/favorites',
        {'userId': userId, 'workerId': workerId},
        useAuthHeaders: true,
      );

      final body = await ApiService.parseAuthenticatedResponse(
        response,
        clearSession: ApiService.clearUserSession,
        loginRoute: '/login',
      );
      return body['isFavorite'] == true;
    } catch (error) {
      rethrow;
    }
  }

  Future<List<WorkerModel>> getFavoriteWorkers(String userId) async {
    try {
      final response = await ApiService.getJson('/users/favorites/$userId', useAuthHeaders: true);

      final body = await ApiService.parseAuthenticatedResponse(
        response,
        clearSession: ApiService.clearUserSession,
        loginRoute: '/login',
      );
      final data = (body['data'] as List<dynamic>? ?? <dynamic>[])
          .cast<Map<String, dynamic>>();

      return data.map(WorkerModel.fromJson).toList();
    } catch (error) {
      rethrow;
    }
  }
}
