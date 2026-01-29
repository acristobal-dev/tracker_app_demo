import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracker_app_demo/app.dart';

import 'config/constants/environment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Environment.initEnvironment();

  runApp(const ProviderScope(child: App()));
}
