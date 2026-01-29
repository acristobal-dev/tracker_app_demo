import 'entities.dart';

class User {
  const User({
    required this.id,
    required this.userName,
    this.locations = const <Location>[],
  });

  final int id;
  final String userName;
  final List<Location> locations;
}
