import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/api_service.dart';
import '../../core/utils/error_message_helper.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'user';
  bool _isLoading = false;
  bool _obscurePassword = true;

  static final RegExp _phonePattern = RegExp(r'^[0-9]{10,15}$');
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.loginByRole(
        role: _selectedRole,
        identifier: _identifierController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      final role = (response['role'] ?? data['role'] ?? _selectedRole).toString().toLowerCase();
      final profileComplete = response['profileComplete'] == true || data['profileComplete'] == true;

      if (role == 'worker') {
        Navigator.pushReplacementNamed(
          context,
          profileComplete ? '/worker/dashboard' : '/worker/complete-profile',
        );
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ErrorMessageHelper.showSnackBar(context, ErrorMessageHelper.auth(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFE0F2FE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Login as user or worker. The app will route you by the account role returned from the server.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'user', label: Text('User')),
                              ButtonSegment(value: 'worker', label: Text('Worker')),
                            ],
                            selected: {_selectedRole},
                            onSelectionChanged: (selected) {
                              setState(() {
                                _selectedRole = selected.first;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _identifierController,
                            labelText: _selectedRole == 'worker' ? 'Phone' : 'Email or Phone',
                            prefixIcon: Icons.person_outline,
                            validator: (value) {
                              final text = value?.trim() ?? '';

                              if (text.isEmpty) {
                                return 'Identifier is required';
                              }

                              if (_selectedRole == 'worker') {
                                if (!_phonePattern.hasMatch(text)) {
                                  return 'Worker login requires a valid phone number';
                                }
                                return null;
                              }

                              final isEmail = text.contains('@');
                              if (isEmail) {
                                if (!_emailPattern.hasMatch(text)) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              }

                              if (!_phonePattern.hasMatch(text)) {
                                return 'Enter a valid phone number';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            labelText: 'Password',
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Minimum 6 characters required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 48,
                            child: AppButton(
                              onPressed: _isLoading ? null : _login,
                              isLoading: _isLoading,
                              label: 'Login as ${_selectedRole == 'worker' ? 'Worker' : 'User'}',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.center,
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.pushNamed(context, '/signup'),
                              style: TextButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                "Don't have an account? Sign up",
                                style: TextStyle(fontSize: 12.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}