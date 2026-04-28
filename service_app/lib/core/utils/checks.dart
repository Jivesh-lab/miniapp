import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../services/location_service.dart';

/// Helper to run an action only if internet is available.
/// Example usage:
/// await runIfConnected(context, () async { Navigator.push(...); });
Future<T?> runIfConnected<T>(BuildContext context, Future<T?> Function() action) async {
  final ok = await ConnectivityService.ensureConnectedOrShow(context);
  if (!ok) return null;
  return await action();
}

/// Helper to run an action only if location service+permission is available.
/// Example usage:
/// await runIfLocationReady(context, () async { fetchNearby(); });
Future<T?> runIfLocationReady<T>(BuildContext context, Future<T?> Function() action) async {
  final ok = await LocationService.ensureServiceAndPermission(context);
  if (!ok) return null;
  return await action();
}
