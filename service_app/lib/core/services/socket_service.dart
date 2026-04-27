import 'dart:convert';

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  IO.Socket? _socket;

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  IO.Socket? get socket => _socket;

  Future<void> initSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final userToken = prefs.getString('user_token');
    final legacyToken = prefs.getString('auth_token');
    final rawWorkerSession = prefs.getString('worker_session');

    String? workerToken;
    if (rawWorkerSession != null && rawWorkerSession.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawWorkerSession);
        if (decoded is Map<String, dynamic>) {
          final parsed = (decoded['token'] ?? '').toString();
          if (parsed.isNotEmpty) {
            workerToken = parsed;
          }
        }
      } catch (_) {
        // Ignore invalid worker session payload.
      }
    }

    final token = (userToken != null && userToken.isNotEmpty)
        ? userToken
        : ((legacyToken != null && legacyToken.isNotEmpty) ? legacyToken : workerToken);

    if (token == null) return;

    _socket = IO.io(
      ApiConfig.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket?.connect();

    _socket?.onConnect((_) {
      print('Connected to Socket.IO Server');
    });

    _socket?.onDisconnect((_) {
      print('Disconnected from Socket.IO Server');
    });

    _socket?.onError((error) {
      print('Socket Error: $error');
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
