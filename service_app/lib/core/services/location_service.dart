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
