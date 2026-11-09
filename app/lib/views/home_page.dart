import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connection/server_connection.dart';
import '../connection/settings_store.dart';
import '../theme.dart';
import '../widgets/touchpad_area.dart';

/// Home — poori screen plain black touchpad. Koi header nahi.
///
///   • single tap            → left click
///   • double tap            → composer
///   • long-press + drag     → scroll (wheel)
///   • neeche ka button      → right click
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<MousifyConnection>();
    final settings = context.read<AppSettings>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: TouchpadArea()),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 14,
            child: _StatusDot(
              state: conn.state,
              onTap: () => _reconnect(context, settings),
            ),
          ),
        ],
      ),
    );
  }

  void _reconnect(BuildContext context, AppSettings settings) {
    final conn = context.read<MousifyConnection>();
    final host = settings.host;
    if (host == null || host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set your PC in Settings first')),
      );
      return;
    }
    HapticFeedback.selectionClick();
    conn.connect(host, settings.port, token: settings.token);
  }
}

/// Chhota connection dot — connected par green, warna hollow. Tap = reconnect.
class _StatusDot extends StatelessWidget {
  final ConnState state;
  final VoidCallback onTap;

  const _StatusDot({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final connected = state == ConnState.connected;
    return GestureDetector(
      onTap: connected ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 28,
        height: 28,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: connected ? 9 : 7,
            height: connected ? 9 : 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected ? AppColors.live : Colors.transparent,
              border: connected
                  ? null
                  : Border.all(color: Colors.white38, width: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}
