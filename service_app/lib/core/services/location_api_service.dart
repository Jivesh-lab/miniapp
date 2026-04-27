import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/api_config.dart';

/// Complete API service for sending location to backend
/// Handles all communication between Flutter and Node.js backend
class LocationApiService {
  static String get baseUrl {
    return ApiConfig.socketUrl;
  }

  static final Map<String, String> _cityCache = {};
  static final Map<String, Future<String>> _cityInFlight = {};

  static String _cityCacheKey(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
  }

  /// Get city name from backend reverse-geocoding API.
  /// Returns city/town/village/county/state, or "Unknown" on failure.
  static Future<String> getCityName(double latitude, double longitude) async {
    final key = _cityCacheKey(latitude, longitude);

    final cached = _cityCache[key];
    if (cached != null) {
      return cached;
    }

    final inFlight = _cityInFlight[key];
    if (inFlight != null) {
      return inFlight;
    }

    final future = _fetchCityName(latitude, longitude, key);
    _cityInFlight[key] = future;

    try {
      return await future;
    } finally {
      _cityInFlight.remove(key);
    }
  }

  static Future<String> _fetchCityName(
    double latitude,
    double longitude,
    String key,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/get-city'),
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'lat': latitude,
              'lng': longitude,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        _cityCache[key] = 'Unknown';
        return 'Unknown';
      }

      final data = jsonDecode(response.body);
      final city = (data['city'] ?? 'Unknown').toString().trim();
      final result = city.isEmpty ? 'Unknown' : city;
      _cityCache[key] = result;
      return result;
    } catch (_) {
      _cityCache[key] = 'Unknown';
      return 'Unknown';
    }
  }

  /// Send user location to backend
  /// Parameters:
  ///   - latitude: User's latitude (double)
  ///   - longitude: User's longitude (double)
  ///   - userToken: JWT token from login (String)
  /// Returns: true if successful, false if failed
  /// Throws: Exception with error message
  static Future<bool> sendLocationToBackend({
    required double latitude,
    required double longitude,
    required String userToken,
  }) async {
    try {
      // Validate inputs
      if (latitude < -90 || latitude > 90) {
        throw Exception('Invalid latitude: must be between -90 and 90');
      }
      if (longitude < -180 || longitude > 180) {
        throw Exception('Invalid longitude: must be between -180 and 180');
      }

      // Prepare request body
      final body = jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      });

      // Make API request
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/update-location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: body,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      // Check response status
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          print('Location sent successfully');
          return true;
        } else {
          throw Exception(responseData['message'] ?? 'Failed to update location');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (response.statusCode == 400) {
        throw Exception('Invalid location data');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending location: $e');
      rethrow;
    }
  }

  /// Batch update location (useful for background tracking)
  /// Sends location along with other user data
  static Future<bool> updateUserProfile({
    required String userToken,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      final body = jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/api/users/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  /// Get nearby workers based on current location
  /// Returns list of workers within specified radius
  static Future<List<dynamic>> getNearbyWorkers({
    required String userToken,
    required double latitude,
    required double longitude,
    String? serviceId,
    double radiusKm = 10,
  }) async {
    try {
      final queryParams = {
        'userLatitude': latitude.toString(),
        'userLongitude': longitude.toString(),
        'radius': radiusKm.toString(),
      };

      if (serviceId != null) {
        queryParams['serviceId'] = serviceId;
      }

      final uri = Uri.parse('$baseUrl/api/workers').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $userToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return responseData['data'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      print('Error getting nearby workers: $e');
      return [];
    }
  }
}
