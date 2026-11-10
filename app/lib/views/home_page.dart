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
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Status bar icons theme ke hisaab se — light me dark icons.
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
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
                      scheme.onSurface.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Upar header — guide chip LEFT side par, wifi/three-dot wali
          // single pill RIGHT side par. Dono alag-alag taraf, merge nahi.
          // Guide chip tap par right ki taraf expand hokar SQUARE-ish
          // guide dikhata hai (2 upar, 2 neeche).
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 18,
            child: const _GuideChip(),
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = AppColors.ink(isDark);
    final wifiIcon = GestureDetector(
      onTap: onOsTap,
      behavior: HitTestBehavior.opaque,
      child: Icon(
        connected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
        color: connected ? ink : ink.withValues(alpha: 0.45),
        size: 26,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // Poori tarah rounded — sideon se gol pill jaisa.
        borderRadius: BorderRadius.circular(26),
        color: AppColors.raised(isDark),
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
            child: Icon(
              Icons.more_horiz_rounded,
              color: ink,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

/// Header guide chip — SINGLE icon, expandable.
///
/// Upar header me LEFT side par (wifi/three-dot wali pill RIGHT side
/// par hai — dono alag-alag taraf, merge nahi).
/// Collapsed: sirf chip — SINGLE icon (touch/hand — gestures ka
/// sab se saaf symbol; brackets "(" ")" code jaisi lagti thi, is
/// liye hata di).
/// Tap par right ki taraf expand hokar SQUARE-ish guide dikhata hai
/// (2×2 grid: 2 upar, 2 neeche — horizontally lamba nahi).
/// Dobara tap par wapas chip. Flat matte, koi border/shadow nahi.
class _GuideChip extends StatefulWidget {
  const _GuideChip();

  @override
  State<_GuideChip> createState() => _GuideChipState();
}

class _GuideChipState extends State<_GuideChip> {
  bool _expanded = false;

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = AppColors.ink(isDark);
    return GestureDetector(
      key: const Key('guide-chip'),
      onTap: _toggle,
      // AnimatedSize — topLeft anchor: pill left edge se right ki
      // taraf aur neeche ki taraf expand hoti hai. Child apni natural
      // size par layout hota hai, animation me clip hota hai.
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        alignment: Alignment.topLeft,
        child: Container(
          width: _expanded ? 220 : 48,
          height: _expanded ? 150 : 48,
          padding: EdgeInsets.symmetric(
            horizontal: _expanded ? 12 : 0,
            vertical: _expanded ? 12 : 0,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_expanded ? 20 : 24),
            color: AppColors.raised(isDark).withValues(alpha: 0.88),
          ),
          child: _expanded
              ? _GuideExpanded(ink: ink)
              : Center(
                  child: Icon(
                    Icons.touch_app_rounded,
                    size: 28,
                    color: ink,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Expanded guide — header (Gestures + tilted icon) + 2×2 grid.
/// 2 upar, 2 neeche — square-ish, horizontally lamba nahi.
class _GuideExpanded extends StatelessWidget {
  final Color ink;

  const _GuideExpanded({required this.ink});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'Gestures',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: ink.withValues(alpha: 0.7),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.touch_app_rounded,
              size: 20,
              color: ink,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _GuideGridItem(
                icon: Icons.open_with_rounded,
                title: 'Drag',
                action: 'Move',
                ink: ink,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GuideGridItem(
                icon: Icons.touch_app_rounded,
                title: 'Tap',
                action: 'Click',
                ink: ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _GuideGridItem(
                icon: Icons.keyboard_rounded,
                title: '2× Tap',
                action: 'Type',
                ink: ink,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GuideGridItem(
                icon: Icons.swap_vert_rounded,
                title: 'Hold+Drag',
                action: 'Scroll',
                ink: ink,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Expanded guide grid ka ek gesture — icon + naam + kaam.
class _GuideGridItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String action;
  final Color ink;

  const _GuideGridItem({
    required this.icon,
    required this.title,
    required this.action,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: ink),
        const SizedBox(height: 2),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: ink,
            height: 1.1,
          ),
        ),
        Text(
          action,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 8,
            color: ink.withValues(alpha: 0.6),
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
