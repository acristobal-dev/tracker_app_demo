import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:widget_to_marker/widget_to_marker.dart';

import '../../../users/domain/domain.dart';
import '../providers/tracker_provider.dart';
import 'widgets.dart';

class MapViewWidget extends ConsumerStatefulWidget {
  const MapViewWidget({
    super.key,
  });

  @override
  ConsumerState<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends ConsumerState<MapViewWidget> {
  GoogleMapController? _mapController;
  StreamSubscription<User>? _userUpdatesSubscription;

  final ValueNotifier<Set<Marker>> _markersNotifier =
      ValueNotifier<Set<Marker>>(<Marker>{});
  final Map<int, Marker> _markers = <int, Marker>{};
  final Map<String, BitmapDescriptor> _iconCache = <String, BitmapDescriptor>{};

  late final Future<String> _mapStyleFuture;

  static const List<Color> _userColors = <Color>[
    Color(0xFF6C3DB7), // Verde Uber
    Color(0xFF1F992A), // Azul
    Color(0xFFB7257F), // Naranja
    Color(0xFFFF5093), // Rosa
    Color(0xFFF2BB41), // Morado
    Color(0xFF5189E5), // Cyan
    Color(0xFFEDD977), // Amarillo
    Color(0xFF8C43FF), // Verde
  ];

  @override
  void initState() {
    super.initState();
    _mapStyleFuture = rootBundle.loadString(
      'assets/map_styles/dark_style.json',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _suscribeUsersUpdates();
      _listenToDisconnect();
    });
  }

  void _cancelUserUpdatesSubscription() async {
    await _userUpdatesSubscription?.cancel();
    _userUpdatesSubscription = null;
  }

  void _suscribeUsersUpdates() {
    _cancelUserUpdatesSubscription();

    _userUpdatesSubscription = ref
        .read(trackerProvider.notifier)
        .userLocationUpdates
        .listen((User updatedUser) async {
          await _updateSingleMarker(updatedUser);

          if (updatedUser.id == ref.read(trackerProvider).ownUser.id) {
            await _updateCamera(updatedUser);
          }
        });
  }

  void _listenToDisconnect() {
    ref.listenManual<TrackerState>(trackerProvider, (
      TrackerState? previous,
      TrackerState next,
    ) {
      if (previous?.isConnected == true && !next.isConnected) {
        _clearAllMarkers();
        _cancelUserUpdatesSubscription();
      }
      if (previous?.isConnected == false && next.isConnected) {
        _suscribeUsersUpdates();
      }
    });
  }

  Future<Marker> _createMarker(User user) async {
    final Location lastLocation = user.locations.first;
    final bool isCurrentUser = ref.read(trackerProvider).ownUser.id == user.id;

    return Marker(
      markerId: MarkerId('user_${user.id}'),
      position: LatLng(lastLocation.latitude, lastLocation.longitude),
      infoWindow: InfoWindow(
        title: isCurrentUser ? 'Tú' : user.userName,
        snippet: user.isOnline
            ? 'Conectado'
            : 'Ultima conexión: ${_formatTime(lastLocation.timestamp)}',
      ),
      icon: await _getIcon(user.id, user.isOnline),
    );
  }

  Future<void> _updateSingleMarker(User user) async {
    if (user.locations.isEmpty) {
      return;
    }

    _markers[user.id] = await _createMarker(user);
    _markersNotifier.value = _markers.values.toSet();
  }

  Color _getColorForUser(int userId) {
    return _userColors[userId % _userColors.length];
  }

  Future<BitmapDescriptor> _getIcon(int userId, bool isOnline) async {
    final Color color = isOnline ? _getColorForUser(userId) : Colors.grey;
    final String key = '${userId}_${isOnline}';

    if (!_iconCache.containsKey(key)) {
      try {
        _iconCache[key] =
            await PinWidget(
              color: color,
              size: 30,
            ).toBitmapDescriptor(
              waitToRender: const Duration(milliseconds: 100),
            );
      } catch (e) {
        _iconCache[key] = BitmapDescriptor.defaultMarkerWithHue(
          isOnline ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        );
      }
    }
    return _iconCache[key]!;
  }

  String _formatTime(DateTime time) {
    final Duration difference = DateTime.now().difference(time);

    final String value = switch (difference) {
      Duration(inSeconds: < 60) => '${difference.inSeconds}s',
      Duration(inMinutes: < 60) => '${difference.inMinutes}min',
      Duration(inHours: < 24) => '${difference.inHours}h',
      _ => '${difference.inDays}d',
    };

    return 'Hace $value';
  }

  Future<void> _updateCamera(User user) async {
    if (_mapController != null && user.locations.isNotEmpty) {
      final Location location = user.locations.first;
      await _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(location.latitude, location.longitude),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _mapStyleFuture,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingStateWidget();
        }

        return Stack(
          children: <Widget>[
            ValueListenableBuilder<Set<Marker>>(
              valueListenable: _markersNotifier,
              builder:
                  (BuildContext context, Set<Marker> value, Widget? child) {
                    return GoogleMap(
                      style: snapshot.data,
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(-12.0653, -75.2049),
                        zoom: 13.0,
                      ),
                      compassEnabled: false,
                      mapToolbarEnabled: false,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      markers: value,
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                    );
                  },
            ),
            Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? child) {
                final TrackerState trackerState = ref.watch(trackerProvider);

                if (!trackerState.isLoading && trackerState.error.isEmpty) {
                  return const SizedBox.shrink();
                }

                return StatusOverlay(
                  isLoading: trackerState.isLoading,
                  error: trackerState.error,
                  onRetry: () async {
                    await CustomAlertDialog.showCustomDialog(
                      context,
                      isConnected: trackerState.isConnected,
                      previousUserName: trackerState.ownUser.userName,
                      onConfirm: (String userName) async {
                        await ref
                            .read(trackerProvider.notifier)
                            .connectAndRegister(userName);
                      },
                    );
                  },
                  onDismiss: () {
                    ref.read(trackerProvider.notifier).clearError();
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _clearAllMarkers() {
    _markers.clear();
    _markersNotifier.value = <Marker>{};
  }

  @override
  Future<void> dispose() async {
    if (context.mounted) {
      await _userUpdatesSubscription?.cancel();
      _mapController?.dispose();
      _markersNotifier.dispose();
      _iconCache.clear();
    }
    super.dispose();
  }
}
