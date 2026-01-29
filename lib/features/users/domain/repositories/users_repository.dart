import 'package:tracker_app_demo/features/users/domain/entities/user.dart';

abstract class UsersRepository {
  Future<List<User>> getAllUsers();
}
