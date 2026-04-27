import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo_coding;
import 'dart:async';

/// Complete location permission and GPS handling service
/// Handles all permission states and provides geocoding (lat/lng → address)
class LocationPermissionHandler {
  /// Check if location services are enabled on the device
  /// Returns: true if enabled, false otherwise
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('Error checking location service: $e');
      return false;
    }
  }

  /// Request location permission from the user
  /// Handles three cases:
  /// - Permission not asked: Shows permission request dialog
  /// - Permission denied: Shows message and returns false
  /// - Permission denied forever: Shows message to open settings
  /// Returns: true if permission granted, false otherwise
  static Future<bool> requestLocationPermission() async {
    try {
      // First check if location service is enabled
      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) {
        debugPrint('Location services disabled');
        return false;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Permission not asked yet - request it
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied by user');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permission denied forever - user must open settings manually
        debugPrint('Location permission denied forever. User must enable in settings.');
        return false;
      }

      // Permission granted
      return true;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  /// Get current GPS location with high accuracy
  /// Timeout: 10 seconds (if location not found, returns null)
  /// Returns: Position object with latitude, longitude, altitude, etc.
  /// Returns: null if permission denied, location disabled, or timeout
  static Future<Position?> getCurrentLocation() async {
    try {
      // Request permission first
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        debugPrint('Location permission not granted');
        return null;
      }

      // Check if location service is enabled
      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) {
        debugPrint('Location service disabled');
        return null;
      }

      // Get current position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      debugPrint(
        'Location obtained: lat=${position.latitude}, lng=${position.longitude}',
      );
      return position;
    } on TimeoutException {
      debugPrint('Location fetch timeout');
      return null;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Convert latitude/longitude to address name using geocoding
  /// Example: lat=19.0176, lng=73.0197 → "Kalamboli"
  /// Returns: City/Address name or null if conversion fails
  static Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // Convert coordinates to address using Google Geocoding API (via geolocator)
      List<geo_coding.Placemark> placemarks =
          await geo_coding.placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        debugPrint('No address found for coordinates');
        return null;
      }

      final placemark = placemarks[0];

      // Return city name, or locality, or name
      final address = placemark.locality ??
          placemark.administrativeArea ??
          placemark.name ??
          'Unknown Location';

      debugPrint('Address found: $address');
      return address;
    } catch (e) {
      debugPrint('Error converting coordinates to address: $e');
      return null;
    }
  }

  /// Get formatted location string for UI display
  /// Returns: "City, State" or "Latitude, Longitude" if conversion fails
  static Future<String> getFormattedLocationString(
    double latitude,
    double longitude,
  ) async {
    try {
      final address = await getAddressFromCoordinates(latitude, longitude);
      if (address != null) {
        return address; // Return city name
      }
      // Fallback to coordinates if address not found
      return '$latitude, $longitude';
    } catch (e) {
      debugPrint('Error formatting location: $e');
      return '$latitude, $longitude';
    }
  }

  /// Stream of location updates in real-time
  /// Updates when user moves more than 10 meters
  /// Useful for tracking user movement over time
  static Stream<Position> watchUserLocation({
    int distanceFilter = 10, // Update when moved 10 meters
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Open device location settings
  /// Useful when permission is denied forever
  static Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint('Error opening location settings: $e');
    }
  }
}
