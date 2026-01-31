import 'package:geolocator/geolocator.dart';

class LocationService {
  Position? _lastPosition;
  final double distanceThreshold = 10.0;

  Future<bool> checkPermissions() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final Position position = await Geolocator.getCurrentPosition();
      _lastPosition = position;

      return position;
    } catch (e) {
      return null;
    }
  }

  Stream<Position> getLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  bool hasLocationChanged(Position newPosition) {
    if (_lastPosition == null) {
      _lastPosition = newPosition;
      return true;
    }

    final double distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    if (distance >= distanceThreshold) {
      _lastPosition = newPosition;
      return true;
    }

    return false;
  }
}
