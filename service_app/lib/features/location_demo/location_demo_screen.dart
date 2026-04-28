import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/location_service.dart';
import '../../core/services/location_permission_handler.dart';
import '../../core/services/location_api_service.dart';

/// Complete home screen with location handling
/// Features:
/// - Fetch location on app start
/// - Show loading/error states
/// - Display coordinates and address
/// - Send location to backend
/// - Handle all permission cases
class LocationDemoScreen extends StatefulWidget {
  final String userToken; // JWT token from login

  const LocationDemoScreen({
    Key? key,
    required this.userToken,
  }) : super(key: key);

  @override
  State<LocationDemoScreen> createState() => _LocationDemoScreenState();
}

class _LocationDemoScreenState extends State<LocationDemoScreen> {
  // Variables to store location data
  double? _latitude;
  double? _longitude;
  String? _address;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isSendingLocation = false;

  @override
  void initState() {
    super.initState();
    // Fetch location when screen loads
    _fetchAndDisplayLocation();
  }

  /// Main function to fetch location and display it
  /// This is called on screen load and on manual refresh
  Future<void> _fetchAndDisplayLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Ask the shared location helper to handle service + permission.
      final ready = await LocationService.ensureServiceAndPermission(context);
      if (!ready) {
        setState(() {
          _errorMessage = 'Location is required. Please enable it in settings.';
          _isLoading = false;
        });
        return;
      }

      // Step 2: Get current location
      final position =
          await LocationPermissionHandler.getCurrentLocation();

      if (position == null) {
        setState(() {
          _errorMessage = 'Could not fetch location. Try again.';
          _isLoading = false;
        });
        return;
      }

      // Step 3: Convert coordinates to address
      final address =
          await LocationPermissionHandler.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      // Step 4: Update UI with location data
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _address = address ?? 'Address not found';
        _isLoading = false;
      });

      // Step 5 (Optional): Send location to backend
      await _sendLocationToBackend();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Send location to backend API
  /// Called automatically after fetching location
  Future<void> _sendLocationToBackend() async {
    if (_latitude == null || _longitude == null) {
      return; // Location not available
    }

    setState(() {
      _isSendingLocation = true;
    });

    try {
      final success = await LocationApiService.sendLocationToBackend(
        latitude: _latitude!,
        longitude: _longitude!,
        userToken: widget.userToken,
      );

      setState(() {
        _isSendingLocation = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location sent to backend')),
        );
      }
    } catch (e) {
      setState(() {
        _isSendingLocation = false;
      });
      debugPrint('Error sending location: $e');
    }
  }

  /// Build loading widget
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Fetching location...',
            style: GoogleFonts.inter(fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// Build error widget with retry button
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Error fetching location',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchAndDisplayLocation,
            child: const Text('Try Again'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: LocationPermissionHandler.openLocationSettings,
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Build success widget with location details
  Widget _buildSuccessState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.teal,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Location',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _address ?? 'Loading...',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Coordinates Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GPS Coordinates',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCoordinateRow('Latitude', _latitude?.toString() ?? 'N/A'),
                  const SizedBox(height: 8),
                  _buildCoordinateRow('Longitude', _longitude?.toString() ?? 'N/A'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Send Location Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSendingLocation ? null : _sendLocationToBackend,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.teal,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: _isSendingLocation
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Send Location to Backend',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Refresh Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _fetchAndDisplayLocation,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Refresh Location',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Info Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ℹ️ How it works:',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. App requests location permission\n'
                  '2. Device provides GPS coordinates\n'
                  '3. Coordinates converted to address\n'
                  '4. Click "Send Location" to update backend\n'
                  '5. Backend stores location in MongoDB',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget to display coordinate pair
  Widget _buildCoordinateRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        Flexible(
          child: SelectableText(
            value,
            style: GoogleFonts.robotoMono(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Location Demo',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildSuccessState(),
    );
  }
}
