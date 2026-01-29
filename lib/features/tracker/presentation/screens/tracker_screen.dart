import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracker_app_demo/features/users/domain/entities/user.dart';

import '../../../users/presentation/providers/providers.dart';
import '../../tracker.dart';

class TrackerScreen extends ConsumerStatefulWidget {
  const TrackerScreen({super.key});

  @override
  ConsumerState<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends ConsumerState<TrackerScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(userProvider.notifier).loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<User>> userAsyncValue = ref.watch(userProvider);

    return Scaffold(
      body: userAsyncValue.when(
        data: (List<User> users) {
          if (users.isEmpty) {
            return const EmptyStateWidget();
          }

          return MapViewWidget(users: users);
        },
        error: (Object error, StackTrace stackTrace) {
          return ErrorStateWidget(
            error: error,
            onRetry: () async {
              await ref.read(userProvider.notifier).loadUsers();
            },
          );
        },
        loading: () => const LoadingStateWidget(),
      ),
    );
  }
}
