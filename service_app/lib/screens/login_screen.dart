import 'package:flutter/material.dart';

import '../core/services/app_api_client.dart';
import '../core/services/api_exception.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AppApiClient.login(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE7F7F3), Color(0xFFF6F7F9)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Welcome back',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Login with your phone or email.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade700,
                                ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _identifierController,
                            decoration: const InputDecoration(
                              labelText: 'Phone or email',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) => (value == null || value.trim().isEmpty)
                                ? 'Enter phone or email'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              ),
                            ),
                            validator: (value) => (value == null || value.length < 6)
                                ? 'Password must be at least 6 characters'
                                : null,
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _isLoading ? null : _submit,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Login'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.pushNamed(context, '/register');
                                  },
                            child: const Text('Create a new account'),
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