import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../widgets/no_internet_screen.dart';

class ConnectivityService {
  ConnectivityService._();
  static final Connectivity _connectivity = Connectivity();

  static Stream<ConnectivityResult> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  /// Returns true for wifi or mobile connection, false otherwise.
  static Future<bool> checkConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Used to guard navigation or API calls.
  /// If connected -> returns true immediately.
  /// If not connected -> shows a full-screen NoInternetScreen and returns false.
  static Future<bool> ensureConnectedOrShow(BuildContext context) async {
    final ok = await checkConnected();
    if (ok) return true;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoInternetScreen(
          onRetry: () async {
            if (await checkConnected()) {
              Navigator.of(context).pop();
            }
          },
        ),
        fullscreenDialog: true,
      ),
    );

    return await checkConnected();
  }
}
