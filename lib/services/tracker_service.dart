import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tracker_app_demo/features/users/domain/domain.dart';

import 'location_service.dart';
import 'socket_service.dart';

/// Estado del servicio de tracking
class TrackerServiceState {
  const TrackerServiceState({
    this.isActive = false,
    this.currentUser = const User(id: 0, userName: ''),
  });

  final bool isActive;
  final User currentUser;

  TrackerServiceState copyWith({
    bool? isActive,
    User? currentUser,
  }) {
    return TrackerServiceState(
      isActive: isActive ?? this.isActive,
      currentUser: currentUser ?? this.currentUser,
    );
  }
}

/// Servicio de tracking usando Notifier (Riverpod 3.x)
class TrackerService extends Notifier<TrackerServiceState> {
  SocketService? _socketService;
  LocationService? _locationService;
  StreamSubscription<Position>? _locationSubscription;

  // Stream de actualizaciones para los providers
  final StreamController<User> _userUpdatesController =
      StreamController<User>.broadcast();
  Stream<User> get userUpdates => _userUpdatesController.stream;

  @override
  TrackerServiceState build() {
    // Cleanup cuando el provider se destruya
    ref.onDispose(() async {
      await _locationSubscription?.cancel();
      await _userUpdatesController.close();
    });

    return const TrackerServiceState();
  }

  /// Inicia el tracking
  Future<void> start({
    required String userName,
    required void Function(int userId, String userName) onRegistered,
    required void Function(Map<String, dynamic>) onUserLocationReceived,
    required void Function(Map<String, dynamic>) onUserConnected,
    required void Function(Map<String, dynamic>) onUserDisconnected,
    required void Function(String) onError,
  }) async {
    if (state.isActive) {
      debugPrint('⚠️ Tracking ya está activo');
      return;
    }

    debugPrint('🚀 Iniciando TrackerService...');

    _locationService = LocationService();

    // Verificar permisos
    final bool hasPermission = await _locationService!.checkPermissions();
    if (!hasPermission) {
      onError('Sin permisos de ubicación');
      return;
    }

    // Configurar socket
    _socketService = SocketService(
      onRegistered: (int userId, String registeredUserName) async {
        debugPrint('✅ Usuario registrado: $registeredUserName ($userId)');

        state = state.copyWith(
          currentUser: User(
            id: userId,
            userName: registeredUserName,
            isOnline: true,
          ),
          isActive: true,
        );

        // Notificar registro exitoso
        onRegistered(userId, registeredUserName);

        // Iniciar tracking de ubicación
        await _startLocationTracking();
      },
      onUserLocationReceived: onUserLocationReceived,
      onUserConnected: onUserConnected,
      onUserDisconnected: onUserDisconnected,
      onError: onError,
    );

    // Conectar socket
    _socketService?.connect();
    await Future<void>.delayed(const Duration(seconds: 1));
    _socketService?.register(userName);
  }

  Future<void> _startLocationTracking() async {
    // Obtener ubicación inicial
    final Position? currentPosition = await _locationService
        ?.getCurrentLocation();
    if (currentPosition != null) {
      _updateLocation(currentPosition);
    }

    // Escuchar cambios de ubicación
    _locationSubscription = _locationService!.getLocationStream().listen((
      Position position,
    ) {
      if (_locationService!.hasLocationChanged(position)) {
        _updateLocation(position);
      }
    });

    debugPrint('📍 Location tracking iniciado');
  }

  void _updateLocation(Position position) {
    state = state.copyWith(
      currentUser: state.currentUser.copyWith(
        locations: <Location>[
          Location(
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: DateTime.now(),
          ),
        ],
      ),
    );

    // Enviar al socket
    _socketService?.sendLocation(
      position.latitude,
      position.longitude,
    );

    // Notificar a los listeners
    _userUpdatesController.add(state.currentUser);
  }

  void emitUserUpdate(User user) {
    _userUpdatesController.add(user);
  }

  /// Detiene el tracking
  Future<void> stop() async {
    if (!state.isActive) return;

    debugPrint('🛑 Deteniendo TrackerService...');

    await _locationSubscription?.cancel();
    _socketService?.disconnect();

    _locationSubscription = null;
    _socketService = null;
    _locationService = null;

    state = const TrackerServiceState();

    debugPrint('✅ TrackerService detenido');
  }
}

/// Provider del servicio de tracking usando NotifierProvider
final NotifierProvider<TrackerService, TrackerServiceState>
trackerServiceProvider = NotifierProvider<TrackerService, TrackerServiceState>(
  TrackerService.new,
);
