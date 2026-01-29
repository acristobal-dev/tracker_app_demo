import 'package:flutter/src/widgets/framework.dart';
import 'package:go_router/go_router.dart';
import 'package:tracker_app_demo/features/tracker/presentation/screens/tracker_screen.dart';

class Routes {
  static const String tracker = '/tracker';

  final GoRouter router = GoRouter(
    initialLocation: tracker,
    routes: <RouteBase>[
      GoRoute(
        path: tracker,
        builder: (BuildContext context, GoRouterState state) {
          return const TrackerScreen();
        },
      ),
    ],
  );
}
