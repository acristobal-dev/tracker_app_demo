import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tracker_app_demo/features/users/domain/domain.dart';
import 'package:tracker_app_demo/features/users/domain/use_cases/user_use_case.dart';
import 'package:tracker_app_demo/features/users/presentation/providers/users_repository_provider.dart';
import 'package:tracker_app_demo/services/location_service.dart';
import 'package:tracker_app_demo/services/socket_service.dart';

final NotifierProvider<TrackerNotifier, TrackerState> trackerProvider =
    NotifierProvider<TrackerNotifier, TrackerState>(TrackerNotifier.new);

class TrackerNotifier extends Notifier<TrackerState> {
  final LocationService _locationService = LocationService();
  SocketService? _socketService;
  StreamSubscription<Position>? _locationSubscription;
  late final UserUseCase _userUseCase;

  StreamController<User>? _userLocationUpdatesController;

  Stream<User> get userLocationUpdates {
    if (_userLocationUpdatesController == null ||
        _userLocationUpdatesController!.isClosed) {
      _userLocationUpdatesController = StreamController<User>.broadcast();
    }
    return _userLocationUpdatesController!.stream;
  }

  @override
  TrackerState build() {
    final UsersRepository usersRepository = ref.read(usersRepositoryProvider);
    _userUseCase = UserUseCase(usersRepository: usersRepository);

    return TrackerState();
  }

  void _ensureControllerOpen() {
    if (_userLocationUpdatesController == null ||
        _userLocationUpdatesController!.isClosed) {
      _userLocationUpdatesController = StreamController<User>.broadcast();
    }
  }

  Future<void> connectAndRegister(String userName) async {
    _ensureControllerOpen();
    state = state.copyWith(isLoading: true);
    final bool hasPermission = await _locationService.checkPermissions();
    if (!hasPermission) {
      state = state.copyWith(
        error: 'Location permissions are denied.',
      );
      return;
    }

    _socketService = SocketService(
      onRegistered: (int userId, String registeredUserName) async {
        await _loadAllUsers();
        await _startTracking(userId, registeredUserName);
        state = state.copyWith(isLoading: false);
      },
      onUserLocationReceived: (Map<String, dynamic> locationData) {
        final User userLocation = User(
          id: locationData['userId'] as int,
          userName: locationData['username'] as String,
          locations: <Location>[
            Location(
              latitude: locationData['latitude'] as double,
              longitude: locationData['longitude'] as double,
              timestamp: DateTime.parse(locationData['timestamp'] as String),
            ),
          ],
          isOnline: true,
        );
        if (userLocation.id != state.ownUser.id) {
          final User? existingUser = state.otherUsers[userLocation.id];

          state = state.copyWith(
            otherUsers: <int, User>{
              ...state.otherUsers,
              userLocation.id: existingUser != null
                  ? existingUser.copyWith(locations: userLocation.locations)
                  : userLocation,
            },
          );

          _userLocationUpdatesController?.add(userLocation);
        }
      },
      onUserConnected: (Map<String, dynamic> userData) {
        final int userId = userData['userId'] as int;

        if (userId != state.ownUser.id) {
          final Map<int, User> updatedUsers = <int, User>{...state.otherUsers};

          if (updatedUsers.containsKey(userId)) {
            updatedUsers[userId] = updatedUsers[userId]!.copyWith(
              isOnline: true,
            );
          } else {
            updatedUsers[userId] = User(
              id: userId,
              userName: userData['username'] as String,
              isOnline: true,
            );
          }

          state = state.copyWith(otherUsers: updatedUsers);

          _userLocationUpdatesController?.add(updatedUsers[userId]!);
        }
      },
      onUserDisconnected: (Map<String, dynamic> userData) {
        final int userId = userData['userId'] as int;

        if (userId != state.ownUser.id) {
          final Map<int, User> updatedUsers = <int, User>{...state.otherUsers};

          if (updatedUsers.containsKey(userId)) {
            updatedUsers[userId] = updatedUsers[userId]!.copyWith(
              isOnline: false,
            );

            state = state.copyWith(otherUsers: updatedUsers);

            _userLocationUpdatesController?.add(updatedUsers[userId]!);
          }
        }
      },
      onError: (String error) {
        state = state.copyWith(
          error: error,
        );
        state = state.copyWith(isLoading: false);
      },
    );

    _socketService?.connect();
    await Future<void>.delayed(const Duration(seconds: 1));
    _socketService?.register(userName);
  }

  Future<void> _loadAllUsers() async {
    try {
      final List<User> response = await _userUseCase.getUsersLocations();
      state = state.copyWith(
        otherUsers: <int, User>{
          for (final User user in response)
            if (user.id != state.ownUser.id) user.id: user,
        },
        isConnected: true,
      );

      for (final User user in response) {
        if (user.id != state.ownUser.id) {
          _userLocationUpdatesController?.add(user);
        }
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load users: $e',
      );
    }
  }

  Future<void> _startTracking(int ownUserId, String ownUserName) async {
    final Position? currentPosition = await _locationService
        .getCurrentLocation();

    if (currentPosition == null) {
      state = state.copyWith(
        error: 'Could not get current location.',
        isLoading: false,
      );

      return;
    }

    final User initialUser = state.ownUser.copyWith(
      id: ownUserId,
      userName: ownUserName,
      locations: <Location>[
        Location(
          latitude: currentPosition.latitude,
          longitude: currentPosition.longitude,
          timestamp: DateTime.now(),
        ),
      ],
      isOnline: true,
    );

    state = state.copyWith(
      ownUser: initialUser,
      isTracking: true,
    );

    _sendOwnUserLocation(
      currentPosition.latitude,
      currentPosition.longitude,
    );

    _locationSubscription = _locationService.getLocationStream().listen((
      Position newPosition,
    ) {
      final bool hasChanged = _locationService.hasLocationChanged(newPosition);

      if (hasChanged) {
        final User updatedUser = state.ownUser.copyWith(
          locations: <Location>[
            Location(
              latitude: newPosition.latitude,
              longitude: newPosition.longitude,
              timestamp: DateTime.now(),
            ),
          ],
        );

        state = state.copyWith(ownUser: updatedUser);

        _sendOwnUserLocation(
          newPosition.latitude,
          newPosition.longitude,
        );
      }
    });
  }

  void _sendOwnUserLocation(double latitude, double longitude) {
    _userLocationUpdatesController?.add(state.ownUser);

    _socketService?.sendLocation(
      latitude,
      longitude,
    );
  }

  Future<void> disconnect() async {
    await _userLocationUpdatesController?.close();
    await _locationSubscription?.cancel();
    _socketService?.disconnect();
    _userLocationUpdatesController = null;
    state = TrackerState();
  }

  void clearError() {
    state = state.copyWith(error: '');
  }
}

class TrackerState {
  TrackerState({
    this.ownUser = const User(id: 0, userName: ''),
    this.isConnected = false,
    this.isTracking = false,
    this.otherUsers = const <int, User>{},
    this.error = '',
    this.isLoading = false,
  });

  final bool isConnected;
  final bool isTracking;
  final User ownUser;
  final Map<int, User> otherUsers;
  final String error;
  final bool isLoading;

  TrackerState copyWith({
    User? ownUser,
    bool? isConnected,
    bool? isTracking,
    Map<int, User>? otherUsers,
    String? error,
    bool? isLoading,
  }) {
    return TrackerState(
      ownUser: ownUser ?? this.ownUser,
      isConnected: isConnected ?? this.isConnected,
      isTracking: isTracking ?? this.isTracking,
      otherUsers: otherUsers ?? this.otherUsers,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
