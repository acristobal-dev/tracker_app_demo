import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tracker_app_demo/features/users/domain/domain.dart';

import '../../../../services/services.dart';

final NotifierProvider<TrackerNotifier, TrackerState> trackerProvider =
    NotifierProvider<TrackerNotifier, TrackerState>(TrackerNotifier.new);

class TrackerNotifier extends Notifier<TrackerState> {
  Stream<User> get userLocationUpdates =>
      ref.read(trackerServiceProvider.notifier).userUpdates;

  @override
  TrackerState build() {
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
          onRegistered: () {
            state = state.copyWith(
              isTracking: true,
              isLoading: false,
            );
          },
          onUserLocationReceived: (Map<String, dynamic> locationData) {
            final User userLocation = User(
              id: locationData['userId'] as int,
              userName: locationData['username'] as String,
              lastLocation: Location(
                latitude: locationData['latitude'] as double,
                longitude: locationData['longitude'] as double,
                timestamp: DateTime.parse(
                  locationData['timestamp'] as String,
                ),
              ),

              isOnline: true,
            );

            final User? existingUser = state.users[userLocation.id];
            state = state.copyWith(
              users: <int, User>{
                ...state.users,
                userLocation.id: existingUser != null
                    ? existingUser.copyWith(
                        lastLocation: userLocation.lastLocation,
                      )
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
              ...state.users,
            };
            if (updatedUsers.containsKey(userId)) {
              updatedUsers[userId] = updatedUsers[userId]!.copyWith(
                isOnline: true,
                lastLocation: newLocation,
              );
            } else {
              updatedUsers[userId] = User(
                id: userId,
                userName: userData['username'] as String,
                isOnline: true,
                lastLocation: newLocation,
              );
            }
            state = state.copyWith(users: updatedUsers);
            ref
                .read(trackerServiceProvider.notifier)
                .emitUserUpdate(updatedUsers[userId]!);
          },
          onUserDisconnected: (Map<String, dynamic> userData) {
            final int userId = userData['userId'] as int;

            final Map<int, User> updatedUsers = <int, User>{
              ...state.users,
            };
            if (updatedUsers.containsKey(userId)) {
              updatedUsers[userId] = updatedUsers[userId]!.copyWith(
                isOnline: false,
              );
              state = state.copyWith(users: updatedUsers);
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
    this.users = const <int, User>{},
    this.error = '',
    this.isLoading = false,
  });

  final bool isConnected;
  final bool isTracking;
  final Map<int, User> users;
  final String error;
  final bool isLoading;

  TrackerState copyWith({
    bool? isConnected,
    bool? isTracking,
    Map<int, User>? users,
    String? error,
    bool? isLoading,
  }) {
    return TrackerState(
      isConnected: isConnected ?? this.isConnected,
      isTracking: isTracking ?? this.isTracking,
      users: users ?? this.users,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
