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
          // Upar khubsurat header — brand + instructions, sab header ke andar.
          // Neeche floating nav ke upar wala glass hint hata diya gaya hai.
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: _TopHeader(
              connected: conn.state == ConnState.connected,
              state: conn.state,
              onStatusTap: () => _reconnect(context, settings),
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

/// Upar wala khubsurat header — poora card, neeche lime line.
///
/// Andar: logo + MOUSIFY + PC Touchpad, right par connection dot,
/// aur uske neeche plain text me instructions — koi glass pill nahi.
class _TopHeader extends StatelessWidget {
  final bool connected;
  final ConnState state;
  final VoidCallback onStatusTap;

  const _TopHeader({
    required this.connected,
    required this.state,
    required this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1B1D), Color(0xFF0E0E0F)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Lime logo square — chhota, halka
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.touch_app_rounded,
                  color: Colors.black,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MOUSIFY',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      connected ? 'PC Touchpad  •  Connected' : 'PC Touchpad  •  Offline',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: connected
                            ? Colors.white.withValues(alpha: 0.65)
                            : Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              _StatusDot(state: state, onTap: onStatusTap),
            ],
          ),
          const SizedBox(height: 10),
          // Lime divider
          Container(
            height: 2,
            width: 32,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          // Instructions — plain text, koi glass pill nahi
          const Row(
            children: [
              _HintItem(icon: Icons.open_with_rounded, text: 'Drag to move'),
              _HintDot(),
              _HintItem(icon: Icons.touch_app_rounded, text: 'Tap to click'),
              _HintDot(),
              _HintItem(icon: Icons.keyboard_rounded, text: 'Double-tap to type'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HintDot extends StatelessWidget {
  const _HintDot();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _HintItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HintItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
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
