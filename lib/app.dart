import 'package:flutter/material.dart';
import 'package:tracker_app_demo/config/theme/app_theme.dart';

import 'config/routes/routes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: Routes().router,
      theme: AppTheme().getTheme(),
      debugShowCheckedModeBanner: false,
    );
  }
}
