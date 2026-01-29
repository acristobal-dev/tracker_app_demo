import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static Future<void> initEnvironment() async {
    await dotenv.load();
  }

  static String get baseApiUrl => dotenv.env['BASE_API_URL'] ?? '';
}
