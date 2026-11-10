import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connection/server_connection.dart';
import '../connection/settings_store.dart';
import '../theme.dart';
import '../widgets/mouse_controls_sheet.dart';
import '../widgets/touchpad_area.dart';

/// Home — poori screen plain black touchpad, upar right corner par chips.
///
/// Right corner: OS chip (server batata hai PC Windows hai, Fedora hai
/// ya Ubuntu) + three-dot button — us se Mouse Controls bottom sheet
/// khulti hai (sensitivity, scroll, double-tap waghera).
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
    final connected = conn.state == ConnState.connected;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: TouchpadArea()),
          // Halki radial glow — touchpad ab plain black nahi, premium lagta hai.
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.35),
                    radius: 0.9,
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Upar right corner — sirf icons wali pill: wifi icon + three-dot.
          // Koi text nahi, dono icons bare.
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 18,
            child: _TopPill(
              connected: connected,
              onOsTap: connected
                  ? null
                  : () => _reconnect(context, settings),
              onMoreTap: () => showMouseControlsSheet(context),
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

/// Upar right corner — sirf icons wali pill: wifi icon + three-dot.
/// Koi text nahi — na "Offline", na OS naam. Dono icons bare hain.
/// Flat matte gray — koi border line, koi shadow nahi.
class _TopPill extends StatelessWidget {
  final bool connected;
  final VoidCallback? onOsTap;
  final VoidCallback onMoreTap;

  const _TopPill({
    required this.connected,
    required this.onOsTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final wifiIcon = GestureDetector(
      onTap: onOsTap,
      behavior: HitTestBehavior.opaque,
      child: Icon(
        connected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
        color: connected
            ? Colors.white
            : Colors.white.withValues(alpha: 0.45),
        size: 26,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // Poori tarah rounded — sideon se gol pill jaisa.
        borderRadius: BorderRadius.circular(26),
        color: AppColors.surfaceGray,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          wifiIcon,
          // Wifi icon aur three dots ke beech kafi gap.
          const SizedBox(width: 30),
          GestureDetector(
            onTap: onMoreTap,
            behavior: HitTestBehavior.opaque,
            child: const Icon(
              Icons.more_horiz_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
