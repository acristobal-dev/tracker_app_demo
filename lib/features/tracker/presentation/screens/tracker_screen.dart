import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/services.dart';
import '../../../users/domain/domain.dart';
import '../../tracker.dart';

class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: const MapViewWidget(),
      floatingActionButton: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          final TrackerState trackerState = ref.watch(trackerProvider);
          final User currentUser = ref.read(trackerServiceProvider).currentUser;

          return FloatingActionButton(
            onPressed: () async {
              if (!trackerState.isLoading) {
                await CustomAlertDialog.showCustomDialog(
                  context,
                  isConnected: trackerState.isConnected,
                  previousUserName: currentUser.userName,
                  onConfirm: (String userName) async {
                    trackerState.isConnected
                        ? await ref.read(trackerProvider.notifier).disconnect()
                        : await ref
                              .read(trackerProvider.notifier)
                              .connectAndRegister(userName);
                  },
                );
              }
            },
            child: Icon(
              trackerState.isLoading
                  ? Icons.replay_outlined
                  : trackerState.isConnected
                  ? Icons.stop
                  : Icons.play_arrow,
            ),
          );
        },
      ),
    );
  }
}
