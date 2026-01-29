import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracker_app_demo/features/users/domain/domain.dart';
import 'package:tracker_app_demo/features/users/infrastructure/infrastructure.dart';

final Provider<UsersRepository> usersRepositoryProvider =
    Provider<UsersRepository>((Ref ref) {
      return UsersRepositoryImpl(
        datasource: UsersDatasourceImpl(),
      );
    });
