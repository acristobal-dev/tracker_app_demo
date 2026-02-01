import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tracker_app_demo/features/users/domain/domain.dart';
import 'package:tracker_app_demo/features/users/domain/use_cases/user_use_case.dart';
import 'package:tracker_app_demo/features/users/presentation/providers/users_repository_provider.dart';

import '../../../../services/services.dart';

final NotifierProvider<TrackerNotifier, TrackerState> trackerProvider =
    NotifierProvider<TrackerNotifier, TrackerState>(TrackerNotifier.new);

class TrackerNotifier extends Notifier<TrackerState> {
  late final UserUseCase _userUseCase;

  Stream<User> get userLocationUpdates =>
      ref.read(trackerServiceProvider.notifier).userUpdates;

  @override
  TrackerState build() {
    final UsersRepository usersRepository = ref.read(usersRepositoryProvider);
    _userUseCase = UserUseCase(usersRepository: usersRepository);

    return TrackerState();
  }

  Future<void> connectAndRegister(String userName) async {
    state = state.copyWith(isLoading: true);
    final Position? position = await ref
        .read(trackerServiceProvider.notifier)
        .startLocationTracking();

    if (position == null) {
      state = state.copyWith(
        error: 'No se pudo obtener la ubicación',
        isLoading: false,
      );
      return;
    }

    await ref
        .read(trackerServiceProvider.notifier)
        .start(
          userName: userName,
          position: position,
          onRegistered: () async {
            await _loadAllUsers().then((_) {
              state = state.copyWith(
                isTracking: true,
                isLoading: false,
              );
            });
          },
          onUserLocationReceived: (Map<String, dynamic> locationData) {
            final User userLocation = User(
              id: locationData['userId'] as int,
              userName: locationData['username'] as String,
              locations: <Location>[
                Location(
                  latitude: locationData['latitude'] as double,
                  longitude: locationData['longitude'] as double,
                  timestamp: DateTime.parse(
                    locationData['timestamp'] as String,
                  ),
                ),
              ],
              isOnline: true,
            );

            final User? existingUser = state.otherUsers[userLocation.id];
            state = state.copyWith(
              otherUsers: <int, User>{
                ...state.otherUsers,
                userLocation.id: existingUser != null
                    ? existingUser.copyWith(locations: userLocation.locations)
                    : userLocation,
              },
            );

            ref
                .read(trackerServiceProvider.notifier)
                .emitUserUpdate(userLocation);
          },
          onUserConnected: (Map<String, dynamic> userData) {
            final int userId = userData['userId'] as int;

            final Location newLocation = Location(
              latitude: userData['latitude'] as double,
              longitude: userData['longitude'] as double,
              timestamp: DateTime.parse(
                userData['timestamp'] as String,
              ),
            );

            final Map<int, User> updatedUsers = <int, User>{
              ...state.otherUsers,
            };
            if (updatedUsers.containsKey(userId)) {
              updatedUsers[userId] = updatedUsers[userId]!.copyWith(
                isOnline: true,
                locations: <Location>[newLocation],
              );
            } else {
              updatedUsers[userId] = User(
                id: userId,
                userName: userData['username'] as String,
                isOnline: true,
                locations: <Location>[newLocation],
              );
            }
            state = state.copyWith(otherUsers: updatedUsers);
          },
          onUserDisconnected: (Map<String, dynamic> userData) {
            final int userId = userData['userId'] as int;

            final Map<int, User> updatedUsers = <int, User>{
              ...state.otherUsers,
            };
            if (updatedUsers.containsKey(userId)) {
              updatedUsers[userId] = updatedUsers[userId]!.copyWith(
                isOnline: false,
              );
              state = state.copyWith(otherUsers: updatedUsers);
              ref
                  .read(trackerServiceProvider.notifier)
                  .emitUserUpdate(updatedUsers[userId]!);
            }
          },
          onError: (String error) {
            state = state.copyWith(error: error, isLoading: false);
          },
        );
  }

  Future<void> _loadAllUsers() async {
    try {
      final User currentUser = ref.read(trackerServiceProvider).currentUser;
      final List<User> response = await _userUseCase.getUsersLocations();
      state = state.copyWith(
        otherUsers: <int, User>{
          for (final User user in response)
            if (user.id != currentUser.id) user.id: user,
        },
        isConnected: true,
      );

      for (final User user in response) {
        if (user.id != currentUser.id && user.locations.isNotEmpty) {
          ref.read(trackerServiceProvider.notifier).emitUserUpdate(user);
        }
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load users: $e',
      );
    }
  }

  Future<void> disconnect() async {
    await ref.read(trackerServiceProvider.notifier).stop();
    state = TrackerState();
  }

  void clearError() {
    state = state.copyWith(error: '');
  }
}

class TrackerState {
  TrackerState({
    this.isConnected = false,
    this.isTracking = false,
    this.otherUsers = const <int, User>{},
    this.error = '',
    this.isLoading = false,
  });

  final bool isConnected;
  final bool isTracking;
  final Map<int, User> otherUsers;
  final String error;
  final bool isLoading;

  TrackerState copyWith({
    bool? isConnected,
    bool? isTracking,
    Map<int, User>? otherUsers,
    String? error,
    bool? isLoading,
  }) {
    return TrackerState(
      isConnected: isConnected ?? this.isConnected,
      isTracking: isTracking ?? this.isTracking,
      otherUsers: otherUsers ?? this.otherUsers,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
