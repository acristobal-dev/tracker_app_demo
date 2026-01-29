import 'package:dio/dio.dart';
import 'package:tracker_app_demo/features/users/domain/domain.dart';
import 'package:tracker_app_demo/features/users/infrastructure/constants/api_constants.dart';
import 'package:tracker_app_demo/features/users/infrastructure/errors/server_errors.dart';

import '../../../../config/constants/environment.dart';
import '../infrastructure.dart';

class UsersDatasourceImpl implements UsersDatasource {
  UsersDatasourceImpl() {
    dio = Dio(
      BaseOptions(
        baseUrl: Environment.baseApiUrl,
        connectTimeout: const Duration(seconds: 10),
      ),
    );
  }

  late final Dio dio;

  @override
  Future<List<User>> getAllUsers() async {
    try {
      const String endpoint = ApiConstants.usersLocationsEndpoint;

      final Response<dynamic> response = await dio.get(endpoint);
      final List<User> user = (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(
            (Map<String, dynamic> userJson) {
              return UserMapper.fromMap(userJson);
            },
          )
          .toList();

      return user;
    } catch (e) {
      throw ServerErrorConnection(
        message: 'Error fetching users',
        error: e.toString(),
      );
    }
  }
}
