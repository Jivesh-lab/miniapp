import 'dart:async';

import '../../services/api_service.dart';
import 'location_service.dart';

class WorkerLocationSyncService {
  WorkerLocationSyncService._();

  static final WorkerLocationSyncService _instance = WorkerLocationSyncService._();
  factory WorkerLocationSyncService() => _instance;

  final WorkerApiService _workerApi = WorkerApiService();
  Timer? _syncTimer;
  bool _isSyncInProgress = false;

  Future<void> start() async {
    if (_syncTimer != null) {
      return;
    }

    await _syncNow();

    _syncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _syncNow();
    });
  }

  void stop() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> _syncNow() async {
    if (_isSyncInProgress) {
      return;
    }

    _isSyncInProgress = true;

    try {
      final session = await _workerApi.getSavedSession();
      if (session == null) {
        return;
      }

      final location = await LocationService.getUserLocation();
      if (location == null) {
        return;
      }

      await _workerApi.updateWorkerLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        isOnline: true,
      );
    } catch (_) {
      // Best-effort sync. The dashboard and cards can still function without it.
    } finally {
      _isSyncInProgress = false;
    }
  }
}
