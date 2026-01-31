import 'package:flutter/material.dart';

import 'widgets.dart';

class StatusOverlay extends StatelessWidget {
  const StatusOverlay({
    required this.isLoading,
    super.key,
    this.error,
    this.onDismiss,
    this.onRetry,
  });

  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: Colors.black.withValues(alpha: 0.8),
        margin: const EdgeInsets.all(24.0),
        child: Padding(
          padding: const EdgeInsetsGeometry.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (isLoading)
                const LoadingStateWidget()
              else if (error != null) ...<Widget>[
                ErrorStateWidget(
                  error: error ?? 'Error desconocido',
                  onRetry: () => onRetry?.call(),
                  onDismiss: () => onDismiss?.call(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
