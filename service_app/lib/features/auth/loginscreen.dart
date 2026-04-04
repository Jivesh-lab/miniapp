import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final String loginUrl =
      "https://exact-ram-64.accounts.dev/sign-in";

  @override
  void initState() {
    super.initState();
    openLogin();
  }

  Future<void> openLogin() async {
    final Uri url = Uri.parse(loginUrl);

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Redirecting to login..."),
      ),
    );
  }
}