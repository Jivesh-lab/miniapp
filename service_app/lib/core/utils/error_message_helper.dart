import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';
import '../services/api_exception.dart';

class ErrorMessageHelper {
  static const String genericApiFailure = 'Something went wrong. Please try again.';
  static const String noWorkerFound = 'No workers available';
  static const String slotUnavailable = 'Selected slot is not available';

  static String generic(Object error) {
    final text = _extract(error);
    if (text.isEmpty) {
      return genericApiFailure;
    }
    return text;
  }

  static String workerList(Object error) {
    final text = _extract(error).toLowerCase();
    if (text.contains('worker not found') || text.contains('no workers')) {
      return noWorkerFound;
    }
    return genericApiFailure;
  }

  static String booking(Object error) {
    final text = _extract(error).toLowerCase();
    if (text.contains('slot') || text.contains('already booked')) {
      return slotUnavailable;
    }
    return genericApiFailure;
  }

  static String auth(Object error) {
    final text = _extract(error).trim();
    final lowered = text.toLowerCase();

    if (text.isEmpty) {
      return genericApiFailure;
    }

    if (lowered.contains('invalid credentials') || lowered.contains('wrong password')) {
      return 'Invalid credentials. Please check and try again.';
    }

    if (lowered.contains('token expired') || lowered.contains('blacklisted')) {
      return 'Token expired, login again';
    }

    if (lowered.contains('user not found') || lowered.contains('account not found')) {
      return 'No account found. Please sign up first.';
    }

    if (lowered.contains('unauthorized') || lowered.contains('token failed')) {
      return 'Session expired or unauthorized. Please log in again.';
    }

    return text;
  }

  static String register(Object error) {
    final text = _extract(error).trim();
    final lowered = text.toLowerCase();

    if (text.isEmpty) {
      return genericApiFailure;
    }

    if (lowered.contains('already exists') || lowered.contains('duplicate')) {
      return text;
    }

    if (lowered.contains('password must be at least 6 characters')) {
      return text;
    }

    if (lowered.contains('invalid phone format') || lowered.contains('invalid email format')) {
      return text;
    }

    return text;
  }

  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static Future<void> showSessionExpiredDialog(
    BuildContext context, {
    String message = 'Session expired or invalid token. Please log in again.',
    String loginRoute = '/login',
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Session issue'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Stay'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                if (!await ConnectivityService.ensureConnectedOrShow(context)) {
                  return;
                }
                Navigator.pushNamedAndRemoveUntil(context, loginRoute, (route) => false);
              },
              child: const Text('Login again'),
            ),
          ],
        );
      },
    );
  }

  static String _extract(Object error) {
    if (error is ApiException) {
      return error.message.trim();
    }
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
