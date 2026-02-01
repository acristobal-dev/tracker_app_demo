import 'package:flutter/cupertino.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:tracker_app_demo/config/constants/environment.dart';

class SocketService {
  IO.Socket? _socket;
  String? _userName;
  int? _userId;

  SocketService({
    this.onRegistered,
    this.onUserLocationReceived,
    this.onUserConnected,
    this.onUserDisconnected,
    this.onError,
  });

  final void Function(int userId, String userName)? onRegistered;
  final void Function(Map<String, dynamic> locationData)?
  onUserLocationReceived;
  final void Function(Map<String, dynamic> userData)? onUserConnected;
  final void Function(Map<String, dynamic> userData)? onUserDisconnected;
  final void Function(String error)? onError;

  bool get isConnected => _socket?.connected ?? false;
  String? get userName => _userName;
  int? get userId => _userId;

  void connect() {
    try {
      final String serverUrl = Environment.baseApiUrl;
      _socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(<String>['websocket'])
            .enableAutoConnect()
            .setTimeout(30000)
            .setReconnectionDelay(3000)
            .setReconnectionDelayMax(10000)
            .setReconnectionAttempts(10)
            .build(),
      );

      _socket?.connect();

      _socket?.onConnectError(
        (dynamic data) {
          debugPrint('❌ Connection error: $data');
          onError?.call('Error de conexión al servidor');
        },
      );

      _socket?.onConnect((_) {
        debugPrint('Socket connected');
        if (_userId != null && _userName != null) {
          debugPrint('🔄 Recuperando sesión: $_userName');
          _socket?.emit('register', <String, dynamic>{'username': _userName!});
        }
      });

      _socket?.onDisconnect((_) {
        debugPrint('❌ Disconnected from server');
      });

      _socket?.on('registered', (dynamic data) {
        _userId = data['userId'] as int?;
        _userName = data['username'] as String?;
        debugPrint('✅ Registered: $_userName (ID: $_userId)');
        onRegistered?.call(_userId!, _userName!);
      });

      _socket?.on('user_location', (dynamic data) {
        debugPrint('📍 User location update: $data');
        onUserLocationReceived?.call(data as Map<String, dynamic>);
      });

      _socket?.on('user_connected', (dynamic data) {
        debugPrint('🟢 User connected: $data');
        onUserConnected?.call(data as Map<String, dynamic>);
      });

      _socket?.on('user_disconnected', (dynamic data) {
        debugPrint('🔴 User disconnected: $data');
        onUserDisconnected?.call(data as Map<String, dynamic>);
      });

      _socket?.on('error', (dynamic data) {
        debugPrint('❌ Socket error: $data');
        onError?.call(
          (data as Map<String, dynamic>)['message'] as String? ??
              'Unknown error',
        );
      });
    } catch (e) {
      debugPrint('❌ Socket connection error: $e');
      onError?.call(e.toString());
    }
  }

  void register(String username) {
    if (_socket?.connected == true) {
      _socket?.emit('register', <String, dynamic>{'username': username});
    } else {
      debugPrint('⚠️ Socket not connected');
      onError?.call('Not connected to server');
    }
  }

  void sendLocation(double latitude, double longitude) {
    if (_socket?.connected == true && _userId != null) {
      _socket?.emit('location_update', <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      });
      debugPrint('📤 Location sent: ($latitude, $longitude)');
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _userId = null;
    _userName = null;
    debugPrint('Socket disconnected manually');
  }
}
