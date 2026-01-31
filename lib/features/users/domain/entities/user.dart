import 'entities.dart';

class User {
  const User({
    required this.id,
    required this.userName,
    this.isOnline = false,
    this.locations = const <Location>[],
  });

  final int id;
  final String userName;
  final bool isOnline;
  final List<Location> locations;

  User copyWith({
    int? id,
    String? userName,
    bool? isOnline,
    List<Location>? locations,
  }) {
    return User(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      isOnline: isOnline ?? this.isOnline,
      locations: locations ?? this.locations,
    );
  }
}
