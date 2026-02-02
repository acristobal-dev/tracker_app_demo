import 'entities.dart';

class User {
  const User({
    required this.id,
    required this.userName,
    this.isOnline = false,
    this.lastLocation,
  });

  final int id;
  final String userName;
  final bool isOnline;
  final Location? lastLocation;

  User copyWith({
    int? id,
    String? userName,
    bool? isOnline,
    Location? lastLocation,
  }) {
    return User(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      isOnline: isOnline ?? this.isOnline,
      lastLocation: lastLocation ?? this.lastLocation,
    );
  }
}
