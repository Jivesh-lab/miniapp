import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();

  /// Ensures that location service is enabled and permission is granted.
  /// Returns true when ready. If not, shows dialogs to guide the user.
  static Future<bool> ensureServiceAndPermission(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      final opened = await _showEnableLocationDialog(context);
      if (opened) {
        // After user returns from settings, re-check.
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      }
      if (!serviceEnabled) return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      // Still denied.
      await _showPermissionDeniedDialog(context);
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied, open app settings.
      await _showPermissionDeniedForeverDialog(context);
      return false;
    }

    return true;
  }

  static Future<bool> _showEnableLocationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Location Required'),
        content: const Text(
            'Location service is turned off. The app requires location to function.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(true);
              await Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );

    return result == true;
  }

  static Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Location Permission'),
        content: const Text(
            'Location permission was denied. Please allow location access to continue.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  static Future<void> _showPermissionDeniedForeverDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Location Permission'),
        content: const Text(
            'Location permission is permanently denied. Please open app settings and enable location.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
import 'package:geolocator/geolocator.dart';

class LocationService {
  static const String _userLocationLatKey = 'user_location_lat';
  static const String _userLocationLngKey = 'user_location_lng';

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission from user
  static Future<LocationPermission> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission;
  }

  /// Check current location permission status
  static Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Get current user location
  /// Returns {latitude, longitude} or null if unable to get location
  static Future<({double latitude, double longitude})?> getUserLocation() async {
    try {
      // Check if location services are enabled
      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) {
        return null;
      }

      // Check and request permission
      var permission = await checkLocationPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openLocationSettings();
        return null;
      }

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return (latitude: position.latitude, longitude: position.longitude);
    } catch (e) {
      return null;
    }
  }

  /// Watch user location in real-time (for worker location updates)
  static Stream<Position> watchUserLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // Update every 10 meters
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        timeLimit: const Duration(seconds: 10),
      ),
    );
  }

  /// Calculate distance between two coordinates in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      final meters = (distanceKm * 1000).round();
      return '$meters m';
    }
    return '${(distanceKm * 10).round() / 10} km';
  }

  /// Check if location is valid
  static bool isValidLocation(double? latitude, double? longitude) {
    return latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }
}
