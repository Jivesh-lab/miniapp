import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/connectivity_service.dart';
import '../services/api_exception.dart';

class ErrorMessageHelper {
  static const String genericApiFailure =
      'Something went wrong. Please try again.';
  static const String noWorkerFound = 'No workers available';
  static const String slotUnavailable = 'Selected slot is not available';
  static const String noConnection =
      'Unable to connect. Please check your internet connection and try again.';
  static const String timedOut =
      'The server is taking too long to respond. Please try again.';
  static const String serverProblem =
      'Something went wrong on our side. Please try again in a moment.';
  static const String tooManyRequests =
      'Too many attempts. Please wait a moment and try again.';
  static const String sessionExpired =
      'Your session has expired. Please log in again.';

  static String generic(Object error, {String? fallback}) {
    final text = _extract(error);
    if (text.isEmpty) {
      return fallback ?? genericApiFailure;
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

    if (lowered.contains('invalid credentials') ||
        lowered.contains('wrong password')) {
      return 'Invalid credentials. Please check and try again.';
    }

    if (lowered.contains('token expired') || lowered.contains('blacklisted')) {
      return sessionExpired;
    }

    if (lowered.contains('user not found') ||
        lowered.contains('account not found')) {
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

    if (lowered.contains('invalid phone format') ||
        lowered.contains('invalid email format')) {
      return text;
    }

    return text;
  }

  /// Shows a single toast-style message. Any message still on screen is
  /// replaced, so errors never pile up in a queue.
  static void showSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          showCloseIcon: true,
        ),
      );
  }

  /// Shows a prebuilt [SnackBar], replacing any message still on screen.
  static void showSnack(BuildContext context, SnackBar snackBar) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..clearSnackBars()
      ..showSnackBar(snackBar);
  }

  /// Shows [error] as a friendly one-at-a-time message.
  static void showError(
    BuildContext context,
    Object error, {
    String? fallback,
  }) {
    showSnackBar(context, generic(error, fallback: fallback));
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
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  loginRoute,
                  (route) => false,
                );
              },
              child: const Text('Login again'),
            ),
          ],
        );
      },
    );
  }

  /// Turns any error into a short message that is safe to show a user:
  /// no exception class names, stack text, raw status codes or empty strings.
  static String _extract(Object error) {
    if (error is ApiException) {
      return _friendlyApi(error.message.trim(), error.statusCode);
    }

    if (error is SocketException ||
        error is http.ClientException ||
        error is HandshakeException) {
      return noConnection;
    }

    if (error is TimeoutException) {
      return timedOut;
    }

    if (error is FormatException) {
      return genericApiFailure;
    }

    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    final lowered = raw.toLowerCase();

    if (lowered.contains('socketexception') ||
        lowered.contains('failed host lookup') ||
        lowered.contains('connection refused') ||
        lowered.contains('connection closed') ||
        lowered.contains('clientexception')) {
      return noConnection;
    }

    if (lowered.contains('timeout') || lowered.contains('timed out')) {
      return timedOut;
    }

    return _isTechnical(raw) ? genericApiFailure : raw;
  }

  static String _friendlyApi(String message, int statusCode) {
    final lowered = message.toLowerCase();

    if (statusCode >= 500) {
      return serverProblem;
    }

    if (statusCode == 429) {
      return tooManyRequests;
    }

    if (message.isEmpty ||
        lowered == 'request failed' ||
        lowered == 'route not found' ||
        lowered == 'unexpected response from server' ||
        _isTechnical(message)) {
      return statusCode == 401 || statusCode == 403
          ? sessionExpired
          : genericApiFailure;
    }

    if (lowered.contains('no token') ||
        lowered.contains('invalid token') ||
        lowered.contains('token revoked')) {
      return sessionExpired;
    }

    return message;
  }

  static bool _isTechnical(String text) {
    final lowered = text.toLowerCase();
    return lowered.length > 160 ||
        lowered.contains('exception') ||
        lowered.contains('typeerror') ||
        lowered.contains("type '") ||
        lowered.contains('null check') ||
        lowered.contains('stack') ||
        lowered.contains('mongo') ||
        lowered.contains('e11000') ||
        lowered.contains('cast to objectid');
  }
}
