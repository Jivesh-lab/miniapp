import 'package:flutter/material.dart';

import '../core/services/connectivity_service.dart';
import '../core/services/app_api_client.dart';
import '../core/services/network_service.dart';

class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  bool _isRetrying = false;

  Future<void> _retry() async {
    setState(() {
      _isRetrying = true;
    });

    final hasInternet = await ConnectivityService.checkConnected();
    if (!mounted) {
      return;
    }

    if (!hasInternet) {
      setState(() {
        _isRetrying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check your internet connection')),
      );
      return;
    }

    final hasSession = await AppApiClient.hasSavedSession();
    if (!mounted) {
      return;
    }

    setState(() {
      _isRetrying = false;
    });

    Navigator.pushReplacementNamed(context, hasSession ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 72, color: Colors.red.shade300),
              const SizedBox(height: 16),
              const Text(
                'No Internet',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your internet connection',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isRetrying ? null : _retry,
                child: Text(_isRetrying ? 'Retrying...' : 'Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
