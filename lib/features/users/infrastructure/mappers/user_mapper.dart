import 'package:tracker_app_demo/features/users/domain/domain.dart';

class UserMapper {
  static User fromMap(Map<String, dynamic> json) {
    return User(
      id: json['userId'] as int,
      userName: json['userName'] as String,
      isOnline: json['isOnline'] as bool? ?? false,
      lastLocation: Location(
        latitude: json['lastLatitude'] as double,
        longitude: json['lastLongitude'] as double,
        timestamp: DateTime.parse(json['timestamp'] as String),
      ),
    );
  }
}
