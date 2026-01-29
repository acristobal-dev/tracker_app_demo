import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracker_app_demo/features/users/domain/use_cases/user_use_case.dart';
import 'package:tracker_app_demo/features/users/infrastructure/errors/server_errors.dart';

import '../../domain/domain.dart';
import 'providers.dart';

final AsyncNotifierProvider<UserNotifier, List<User>> userProvider =
    AsyncNotifierProvider<UserNotifier, List<User>>(UserNotifier.new);

class UserNotifier extends AsyncNotifier<List<User>> {
  late final UserUseCase _userUseCase;

  Future<void> loadUsers() async {
    state = const AsyncValue<List<User>>.loading();

    try {
      final List<User> users = await _userUseCase.getUsersLocations();
      state = AsyncValue<List<User>>.data(users);
    } on ServerErrorConnection catch (e) {
      state = AsyncValue<List<User>>.error(e, StackTrace.current);
    } catch (e, stack) {
      state = AsyncValue<List<User>>.error(e, stack);
    }
  }

  @override
  FutureOr<List<User>> build() {
    final UsersRepository usersRepository = ref.read(usersRepositoryProvider);
    _userUseCase = UserUseCase(usersRepository: usersRepository);

    return <User>[];
  }
}
