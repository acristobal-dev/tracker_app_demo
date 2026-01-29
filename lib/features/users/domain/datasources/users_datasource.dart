import '../entities/entities.dart';

abstract class UsersDatasource {
  Future<List<User>> getAllUsers();
}
