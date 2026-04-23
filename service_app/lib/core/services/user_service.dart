import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/worker_model.dart';
import '../models/user_data_model.dart';
import 'api_service.dart';

class UserService {
  static const String _userDataKey = 'user_data';

  /// Save user data locally
  Future<void> saveUserData(UserDataModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, jsonEncode(user.toJson()));
    } catch (e) {
      rethrow;
    }
  }

  /// Get cached user data
  Future<UserDataModel?> getCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_userDataKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return UserDataModel.fromJson(json);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clear cached user data
  Future<void> clearCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
    } catch (e) {
      rethrow;
    }
  }

  /// Get user name from cache
  Future<String?> getUserName() async {
    try {
      final user = await getCachedUserData();
      return user?.name;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await ApiService.getJson('/users/profile', useAuthHeaders: true);
      final body = await ApiService.parseAuthenticatedResponse(
        response,
        clearSession: ApiService.clearUserSession,
        loginRoute: '/login',
      );

      final data = (body['data'] as Map<String, dynamic>? ?? <String, dynamic>{});
      
      // Save user data locally
      final user = UserDataModel.fromJson(data);
      await saveUserData(user);

      return data;
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
