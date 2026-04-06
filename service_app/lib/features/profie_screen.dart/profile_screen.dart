import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // User data (dummy)
  final String userName = 'John Doe';
  final String userPhone = '+91 98765 43210';
  final String userEmail = 'john.doe@example.com';
  final String userAvatar = 'JD';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final padding = isMobile ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(isMobile),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            _buildProfileCard(isMobile, padding),
            const SizedBox(height: 32),

            // Options Section
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
              icon: Icons.bookmark_outline,
              title: 'My Bookings',
              subtitle: 'View all your service bookings',
              onTap: () {
                Navigator.pushNamed(context, '/my-bookings');
              },
            ),
            const SizedBox(height: 12),
            _buildOptionItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'Notification, privacy & security',
              onTap: _showSettingsModal,
            ),
            const SizedBox(height: 12),
            _buildOptionItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help with your account',
              onTap: _showHelpModal,
            ),
            const SizedBox(height: 32),

            // Danger Zone
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
            const SizedBox(height: 24),

            // App Version
            Center(
              child: Text(
                'App Version 1.0.0',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  PreferredSize _buildAppBar(bool isMobile) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
              return;
            }
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
        centerTitle: false,
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isMobile, double padding) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    userAvatar,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Edit Button
              GestureDetector(
                onTap: _showEditProfileModal,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
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
          const SizedBox(height: 16),
          // Phone
          Row(
            children: [
              Icon(
                Icons.phone_outlined,
                color: Colors.grey.shade600,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                userPhone,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
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
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.shade50
                    : AppColors.primary.withOpacity(0.1),
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
                      color: isDestructive
                          ? Colors.red
                          : const Color(0xFF1F2937),
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
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Edit Profile',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 20),
              _buildEditField('Name', userName),
              const SizedBox(height: 16),
              _buildEditField('Email', userEmail),
              const SizedBox(height: 16),
              _buildEditField('Phone', userPhone),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Profile updated successfully!',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save Changes',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: value),
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Settings',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 20),
              _buildSettingsTile(
                'Push Notifications',
                'Receive booking updates',
                true,
              ),
              const SizedBox(height: 16),
              _buildSettingsTile(
                'Email Notifications',
                'Receive email updates',
                true,
              ),
              const SizedBox(height: 16),
              _buildSettingsTile(
                'SMS Notifications',
                'Receive SMS updates',
                false,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile(String title, String subtitle, bool value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
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
        Switch(
          value: value,
          onChanged: (val) {},
          activeColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withOpacity(0.3),
        ),
      ],
    );
  }

  void _showHelpModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Help & Support',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 20),
              _buildHelpItem(
                'FAQ',
                'Frequently asked questions',
                Icons.help_outline,
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                'Contact Us',
                'Get in touch with support',
                Icons.email_outlined,
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                'Privacy Policy',
                'View our privacy policy',
                Icons.privacy_tip_outlined,
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                'Terms & Conditions',
                'View terms & conditions',
                Icons.description_outlined,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHelpItem(String title, String subtitle, IconData icon) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
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
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Logout',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          content: Text(
            'Are you sure you want to logout from your account?',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Logged out successfully!',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              child: Text(
                'Logout',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}