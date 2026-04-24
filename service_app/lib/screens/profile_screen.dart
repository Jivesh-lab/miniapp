import 'package:flutter/material.dart';

import '../core/services/app_api_client.dart';
import '../core/services/api_exception.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _profile = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await AppApiClient.getProfile();
      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.statusCode == 401) {
        await AppApiClient.clearSession();
        if (!mounted) {
          return;
        }

        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await AppApiClient.logout();
    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadProfile,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: Color(0xFFE7F7F3),
                      child: Icon(Icons.person, size: 36, color: Color(0xFF0F766E)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      (_profile['name'] ?? 'Guest').toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your account details from the backend',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 24),
                    _ProfileTile(label: 'Email', value: (_profile['email'] ?? '-').toString()),
                    const SizedBox(height: 12),
                    _ProfileTile(label: 'Phone', value: (_profile['phone'] ?? '-').toString()),
                    const SizedBox(height: 12),
                    _ProfileTile(label: 'User ID', value: (_profile['id'] ?? _profile['_id'] ?? '-').toString()),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loadProfile,
                      child: const Text('Refresh profile'),
                    ),
                  ],
                ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}