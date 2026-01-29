import 'package:tracker_app_demo/features/users/domain/domain.dart';
import 'package:tracker_app_demo/features/users/infrastructure/mappers/mappers.dart';

class UserMapper {
  static User fromMap(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      userName: json['username'] as String,
      locations: (json['locations'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(
            (Map<String, dynamic> locationJson) {
              return LocationMapper.fromMap(locationJson);
            },
          )
          .toList(),
    );
  }
}
