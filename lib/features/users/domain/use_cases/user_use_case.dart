import '../domain.dart';

class UserUseCase {
  UserUseCase({required this.usersRepository});

  final UsersRepository usersRepository;

  Future<List<User>> getUsersLocations() async {
    return await usersRepository.getAllUsers();
  }
}
