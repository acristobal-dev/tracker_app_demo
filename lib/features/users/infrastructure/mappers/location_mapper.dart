import 'package:tracker_app_demo/features/users/domain/domain.dart';

class LocationMapper {
  static Location fromMap(Map<String, dynamic> json) {
    return Location(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
