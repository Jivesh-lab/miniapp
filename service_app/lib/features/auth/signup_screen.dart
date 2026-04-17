import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/api_service.dart';
import '../../core/utils/error_message_helper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _role;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _didReadRouteArgs = false;

  static final RegExp _phonePattern = RegExp(r'^[0-9]{10,15}$');
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didReadRouteArgs) {
      return;
    }

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is String && (arguments == 'user' || arguments == 'worker')) {
      _role = arguments;
    }

    _didReadRouteArgs = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int _passwordScore(String value) {
    var score = 0;
    if (value.length >= 6) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    return score;
  }

  String _passwordLabel(String value) {
    final score = _passwordScore(value);
    if (score <= 1) return 'Weak';
    if (score == 2) return 'Okay';
    if (score == 3) return 'Strong';
    return 'Very strong';
  }

  Color _passwordColor(String value) {
    final score = _passwordScore(value);
    if (score <= 1) return const Color(0xFFDC2626);
    if (score == 2) return const Color(0xFFEA580C);
    if (score == 3) return const Color(0xFF0E7490);
    return const Color(0xFF15803D);
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      ErrorMessageHelper.showSnackBar(context, 'Please accept terms to continue');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.registerUser(
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      ErrorMessageHelper.showSnackBar(
        context,
        'Account created. Please log in.',
      );

      Navigator.pushReplacementNamed(context, '/login', arguments: 'user');
    } catch (e) {
      if (!mounted) return;
      ErrorMessageHelper.showSnackBar(
          context, ErrorMessageHelper.register(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registerWorker() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      ErrorMessageHelper.showSnackBar(context, 'Please accept terms to continue');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.registerWorker(
        name: _nameController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      ErrorMessageHelper.showSnackBar(
        context,
        'Worker account created. Please complete your profile after login.',
      );

      Navigator.pushReplacementNamed(context, '/login', arguments: 'worker');
    } catch (e) {
      if (!mounted) return;
      ErrorMessageHelper.showSnackBar(context, ErrorMessageHelper.register(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openSignupRole(String role) {
    Navigator.pushNamed(context, '/signup', arguments: role);
  }

  Widget _buildRoleChoice() {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFFFF7ED)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Create your account',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pick the account type you want to create. Worker signup stays minimal and profile completion happens after login.',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _openSignupRole('user'),
                        icon: const Icon(Icons.person_outline),
                        label: const Text('Sign up as User'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _openSignupRole('worker'),
                        icon: const Icon(Icons.work_outline),
                        label: const Text('Sign up as Worker'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignupForm() {
    final isWorker = _role == 'worker';
    final title = isWorker ? 'Worker Sign Up' : 'User Sign Up';
    final subtitle = isWorker
        ? 'Create a worker account with basic details only. Complete your profile after login.'
        : 'Create a user account with email, phone, and password.';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFE0F2FE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
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
                        Text(
                          title,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Name is required';
                            }
                            if (text.length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Phone is required';
                            }
                            if (!_phonePattern.hasMatch(text)) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        if (!isWorker) ...[
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                return 'Email is required';
                              }
                              if (!_emailPattern.hasMatch(text)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
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
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Password is required';
                            }
                            if (text.length < 6) {
                              return 'Minimum 6 characters required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.grey.shade200,
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (_passwordScore(_passwordController.text) / 4).clamp(0, 1),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: _passwordColor(_passwordController.text),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Password strength: ${_passwordLabel(_passwordController.text)}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: _passwordColor(_passwordController.text),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm password',
                            prefixIcon: const Icon(Icons.lock_person_outlined),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if ((value ?? '').isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          value: _acceptedTerms,
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() => _acceptedTerms = value == true);
                                },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'I agree to terms and privacy policy',
                            style: GoogleFonts.manrope(fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : isWorker
                                    ? _registerWorker
                                    : _registerUser,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(isWorker ? 'Create Worker Account' : 'Create User Account'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pushReplacementNamed(context, '/login'),
                          child: const Text('Already have an account? Login'),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_role == null) {
      return _buildRoleChoice();
    }

    return _buildSignupForm();
  }
}