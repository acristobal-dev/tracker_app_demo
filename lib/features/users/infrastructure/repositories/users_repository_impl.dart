import '../../domain/domain.dart';

class UsersRepositoryImpl implements UsersRepository {
  UsersRepositoryImpl({required this.datasource});

  final UsersDatasource datasource;

  @override
  Future<List<User>> getAllUsers() => datasource.getAllUsers();
}
