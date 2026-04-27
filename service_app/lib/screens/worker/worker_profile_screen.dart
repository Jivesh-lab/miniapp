import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/error_message_helper.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../services/api_service.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  final _api = WorkerApiService();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _profile = <String, dynamic>{};
  WorkerSession? _session;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final session = await _api.getSavedSession();
      final profile = await _api.getWorkerProfile();

      if (!mounted) {
        return;
      }

      setState(() {
        _session = session;
        _profile = profile;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _error = ErrorMessageHelper.generic(error);
      });
    }
  }

  Future<void> _logout() async {
    await _api.logout();
    if (!mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<void> _showLogoutConfirmation() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _logout();
    }
  }

  Future<void> _showEditProfile() async {
    await Navigator.pushNamed(context, '/worker/complete-profile');
    if (!mounted) {
      return;
    }
    await _loadProfile();
  }

  String _readValue(String key, {String fallback = 'Not set'}) {
    final value = (_profile[key] ?? '').toString().trim();
    if (value.isEmpty) {
      return fallback;
    }
    return value;
  }

  String _serviceName() {
    final service = _profile['serviceId'];
    if (service is Map<String, dynamic>) {
      final name = (service['name'] ?? '').toString().trim();
      if (name.isNotEmpty) {
        return name;
      }
      final id = (service['_id'] ?? service['id'] ?? '').toString().trim();
      if (id.isNotEmpty) {
        return id;
      }
    }

    return _readValue('serviceId');
  }

  List<String> _skills() {
    final raw = _profile['skills'];
    if (raw is List) {
      return raw
          .map((skill) => skill.toString().trim())
          .where((skill) => skill.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
              return;
            }
            Navigator.pushReplacementNamed(context, '/worker/dashboard');
          },
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadProfile,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    children: [
                      ResponsiveContent(
                        maxWidth: 760,
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: _buildHeroCard(),
                      ),
                      const SizedBox(height: 12),
                      ResponsiveContent(
                        maxWidth: 760,
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: _buildAccountCard(),
                      ),
                      const SizedBox(height: 12),
                      ResponsiveContent(
                        maxWidth: 760,
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: _buildDangerZone(),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'App Version 1.0.0',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeroCard() {
    final name = _readValue('name', fallback: 'Worker');
    final letter = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'W';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                letter,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _readValue('email', fallback: 'No email'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  _readValue('phone', fallback: 'No phone number'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showEditProfile,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard() {
    final skills = _skills();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionItem(
            icon: Icons.work_outline,
            title: 'Service',
            subtitle: _serviceName(),
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildOptionItem(
            icon: Icons.payments_outlined,
            title: 'Price',
            subtitle: _readValue('price', fallback: 'Not set'),
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildOptionItem(
            icon: Icons.location_on_outlined,
            title: 'Location',
            subtitle: _readValue('location'),
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildOptionItem(
            icon: Icons.badge_outlined,
            title: 'Skills',
            subtitle: skills.isEmpty ? 'No skills listed' : skills.join(', '),
            onTap: () {},
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showEditProfile,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Profile'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _session == null
                  ? null
                  : () => Navigator.pushNamed(
                        context,
                        '/worker/bookings',
                        arguments: _session,
                      ),
              icon: const Icon(Icons.list_alt_outlined),
              label: const Text('View Bookings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Danger Zone',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionItem(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out from your account',
            isDestructive: true,
            onTap: _showLogoutConfirmation,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDestructive ? Colors.red.shade200 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.shade50
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.red : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDestructive ? Colors.red : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
