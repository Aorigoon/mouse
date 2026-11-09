import 'package:flutter/material.dart';

import '../connection/server_connection.dart';
import '../theme.dart';

/// Connection status pill — connected par green dot. Tap = reconnect.
class StatusPill extends StatelessWidget {
  final ConnState state;
  final String? label;
  final VoidCallback? onTap;

  const StatusPill({
    super.key,
    required this.state,
    this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (dotColor, dotBorder, text) = switch (state) {
      ConnState.connected => (AppColors.live, AppColors.live, label ?? 'Connected'),
      ConnState.connecting => (scheme.onSurfaceVariant, scheme.onSurfaceVariant, 'Connecting…'),
      ConnState.waitingPair => (scheme.onSurfaceVariant, scheme.onSurfaceVariant, 'Pairing required'),
      ConnState.disconnected => (Colors.transparent, scheme.onSurfaceVariant, 'Offline'),
    };
    return Tooltip(
      message: state == ConnState.connected ? '' : 'Tap to connect',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: scheme.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  border: Border.all(color: dotBorder, width: 1),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
