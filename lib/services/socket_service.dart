import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:tracker_app_demo/config/constants/environment.dart';

class SocketService {
  IO.Socket? _socket;
  bool _wasConnected = false;

  SocketService({
    this.onRegistered,
    this.onUserLocationReceived,
    this.onUserConnected,
    this.onUserDisconnected,
    this.onError,
  });

  final void Function(Map<String, dynamic> response)? onRegistered;
  final void Function(Map<String, dynamic> locationData)?
  onUserLocationReceived;
  final void Function(Map<String, dynamic> userData)? onUserConnected;
  final void Function(Map<String, dynamic> userData)? onUserDisconnected;
  final void Function(String error)? onError;

  bool get isConnected => _socket?.connected ?? false;

  void connect({
    required String userName,
    required Position position,
  }) {
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

      _socket?.onConnectError(
        (dynamic data) {
          debugPrint('❌ Connection error: $data');

          if (!_wasConnected) {
            onError?.call('Error de conexión al servidor');
          } else {
            debugPrint('🔄 Reintentando reconexión... (error silenciado)');
          }
        },
      );

      _socket?.onConnect((_) {
        debugPrint('Socket connected');
        _wasConnected = true;
        _register(userName, position);
      });

      _socket?.onDisconnect((_) {
        debugPrint('❌ Disconnected from server');
      });

      _socket?.on('registered', (dynamic data) {
        onRegistered?.call(data as Map<String, dynamic>);
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

      _socket?.connect();
    } catch (e) {
      debugPrint('❌ Socket connection error: $e');
      onError?.call(e.toString());
    }
  }

  void _register(String username, Position? position) {
    if (_socket?.connected == true) {
      _socket?.emit('register', <String, dynamic>{
        'username': username,
        'latitude': position?.latitude,
        'longitude': position?.longitude,
      });
    } else {
      debugPrint('⚠️ Socket not connected');
      onError?.call('Not connected to server');
    }
  }

  void sendLocation(double latitude, double longitude) {
    if (_socket?.connected == true) {
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
    _wasConnected = false;
    debugPrint('Socket disconnected manually');
  }
}
