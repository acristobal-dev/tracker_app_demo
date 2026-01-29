import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:widget_to_marker/widget_to_marker.dart';

import '../../../users/domain/domain.dart';
import 'widgets.dart';

class MapViewWidget extends StatefulWidget {
  const MapViewWidget({
    required this.users,
    super.key,
  });

  final List<User> users;

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  String? _mapStyle;

  final Set<Marker> _markers = <Marker>{};
  final Set<Polyline> _polylines = <Polyline>{};
  final Set<Circle> _circles = <Circle>{};

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadMapStyle();
      await _prepareMapData();
    });
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await rootBundle.loadString(
      'assets/map_styles/dark_style.json',
    );
  }

  Future<void> _prepareMapData() async {
    if (widget.users.isEmpty) return;

    // Limpiar todo
    _markers.clear();
    _polylines.clear();
    _circles.clear();

    for (int i = 0; i < widget.users.length; i++) {
      final User user = widget.users[i];
      final ui.Color color = _userColors[i % _userColors.length];

      // 1. Agregar polyline (ruta)
      if (user.locations.length >= 2) {
        _polylines.add(
          Polyline(
            polylineId: PolylineId('route_$i'),
            points: user.locations.map((Location loc) {
              return LatLng(loc.latitude, loc.longitude);
            }).toList(),
            color: color.withValues(alpha: 0.4),
            width: 4,
          ),
        );
      }

      // 2. Agregar círculos rojos (puntos intermedios)
      for (int j = 0; j < user.locations.length - 1; j++) {
        final Location loc = user.locations[j];
        _circles.add(
          Circle(
            circleId: CircleId('circle_${i}_$j'),
            center: LatLng(loc.latitude, loc.longitude),
            radius: 8, // metros
            fillColor: Colors.red.withValues(alpha: 0.8),
            strokeColor: Colors.white,
            strokeWidth: 2,
          ),
        );
      }

      // 3. Agregar marcador (última ubicación)
      final Location lastLocation = user.locations.last;
      _markers.add(
        Marker(
          markerId: MarkerId('user_$i'),
          position: LatLng(lastLocation.latitude, lastLocation.longitude),
          infoWindow: InfoWindow(title: user.userName),
          icon: await PinWidget(
            color: color,
            size: 30,
          ).toBitmapDescriptor(),
        ),
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final User fisrtUser = widget.users.first;
    final Location lastLocation = fisrtUser.locations.last;

    return GoogleMap(
      style: _mapStyle,
      initialCameraPosition: CameraPosition(
        target: LatLng(lastLocation.latitude, lastLocation.longitude),
        zoom: 15.0,
      ),
      compassEnabled: false,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      markers: _markers,
      polylines: _polylines,
      circles: _circles,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
