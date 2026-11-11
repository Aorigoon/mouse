import 'dart:async';

import 'package:flutter/material.dart';
import '../utils/haptics.dart';
import 'package:provider/provider.dart';

import '../connection/server_connection.dart';
import '../theme.dart';
import 'camera_icon.dart';
import 'close_icon.dart';
import 'play_icon.dart';
import 'rotate_ccw_icon.dart';
import 'rotate_cw_icon.dart';
import 'volume_down_icon.dart';
import 'volume_up_icon.dart';

/// Mouse page ka media-tools stick — quick-tools stick jaisa hi,
/// lekin media ke liye. Right edge par tools stick ke UPAR (alag
/// stick — tools stick ke saath merge NAHI hota).
///
/// Trigger (play icon) dabao to stick seedha upar expand hoti hai
/// (54 chaudi), tools trigger ke upar aate hain, trigger X ban
/// jata hai. Tools: Rewind 10s, Play/Pause (safed), Forward 10s,
/// Volume up/down, Screenshot. Tool dabane par stick khuli rehti
/// hai — band sirf X se hoti hai.
///
/// `openStick` — dono sticks (tools + media) ek hi notifier share
/// karte hain taaki ek waqt me sirf ek khuli ho: ek khule to
/// dusri band ho jati hai. Null ho to stick akeli kaam karti hai.
class MediaToolsStick extends StatefulWidget {
  final ValueNotifier<String?>? openStick;
  final String stickId;

  const MediaToolsStick({
    super.key,
    this.openStick,
    this.stickId = 'media',
  });

  @override
  State<MediaToolsStick> createState() => _MediaToolsStickState();
}

class _MediaToolsStickState extends State<MediaToolsStick> {
  bool _expanded = false;
  double? _volume;
  late final MousifyConnection _conn;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _conn = context.read<MousifyConnection>();
    _sub = _conn.events.listen(_onEvent);
    widget.openStick?.addListener(_onOpenStickChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_conn.isReady) _conn.send({'t': 'volume-get'});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    widget.openStick?.removeListener(_onOpenStickChanged);
    super.dispose();
  }

  /// Dusri stick khuli to ye band ho jaye (ek waqt me ek hi stick).
  void _onOpenStickChanged() {
    if (widget.openStick?.value != widget.stickId && _expanded) {
      if (mounted) setState(() => _expanded = false);
    }
  }

  void _onEvent(Map<String, dynamic> msg) {
    if (!mounted) return;
    if (msg['t'] != 'volume') return;
    final v = msg['value'];
    if (v is int) setState(() => _volume = v.toDouble());
  }

  void _toggle() {
    if (!_expanded) {
      setState(() => _expanded = true);
      widget.openStick?.value = widget.stickId;
    } else {
      setState(() => _expanded = false);
      if (widget.openStick?.value == widget.stickId) {
        widget.openStick?.value = null;
      }
    }
  }

  void _media(String action) {
    Haptics.click();
    _conn.send({'t': 'media', 'action': action});
  }

  void _setVolume(double v) {
    v = v.clamp(0, 100);
    setState(() => _volume = v);
    _conn.send({'t': 'volume', 'value': v.round()});
  }

  void _screenshot() {
    if (!_conn.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect to your PC in Settings first')),
      );
      return;
    }
    Haptics.impact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PC par "Capture" dialog confirm karo…'),
        duration: Duration(seconds: 3),
      ),
    );
    _conn.send({'t': 'screenshot'});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = AppColors.ink(isDark);
    return Material(
      color: AppColors.raised(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(27),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tools — khulne par upar ki taraf aate hain.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.94, end: 1.0)
                        .animate(animation),
                    alignment: Alignment.bottomCenter,
                    child: child,
                  ),
                );
              },
              child: _expanded
                  ? _MediaToolsColumn(
                      key: const ValueKey('media-tools-open'),
                      ink: ink,
                      onMedia: _media,
                      onVolume: (delta) =>
                          _setVolume((_volume ?? 0) + delta),
                      onScreenshot: _screenshot,
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('media-tools-closed'),
                    ),
            ),
            // Trigger — band ho to play icon, khuli ho to cross (X).
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                key: const Key('media-tools-button'),
                customBorder: const CircleBorder(),
                onTap: _toggle,
                child: SizedBox(
                  width: 54,
                  height: 54,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.6, end: 1.0)
                                .animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _expanded
                          ? CloseIcon(
                              key: const ValueKey('media-tools-close'),
                              size: 26,
                              color: ink,
                            )
                          : PlayIcon(
                              key: const ValueKey('media-tools-play'),
                              size: 24,
                              color: ink,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stick ke tool buttons — 54×54, sirf icon, koi text nahi.
/// Upar se neeche: Rewind 10s, Play (safed), Forward 10s,
// Volume up, Volume down, Screenshot.
class _MediaToolsColumn extends StatelessWidget {
  final Color ink;
  final void Function(String action) onMedia;
  final void Function(double delta) onVolume;
  final VoidCallback onScreenshot;

  const _MediaToolsColumn({
    super.key,
    required this.ink,
    required this.onMedia,
    required this.onVolume,
    required this.onScreenshot,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StickBtn(
            key: const Key('media-tool-rewind'),
            // Lucide rotate-ccw — Material replay_10 ki jagah.
            // (Lucide par "10" wala version nahi hai.)
            iconWidget: RotateCcwIcon(size: 20, color: ink),
            ink: ink,
            onTap: () => onMedia('rewind10'),
          ),
          const SizedBox(height: 4),
          _StickBtn(
            key: const Key('media-tool-play'),
            // Lucide play — safed gol background HATA diya (Zain:
            // "pause icon ke peeche background mat lagao, sirf icon").
            // Ab sirf icon hai, baaki tools ki tarah theme ink me.
            iconWidget: PlayIcon(size: 20, color: ink),
            ink: ink,
            onTap: () => onMedia('playpause'),
          ),
          const SizedBox(height: 4),
          _StickBtn(
            key: const Key('media-tool-forward'),
            // Lucide rotate-cw — Material forward_10 ki jagah.
            iconWidget: RotateCwIcon(size: 20, color: ink),
            ink: ink,
            onTap: () => onMedia('forward10'),
          ),
          const SizedBox(height: 4),
          _StickBtn(
            key: const Key('media-tool-vol-up'),
            // Lucide volume-2 — Material volume_up ki jagah.
            iconWidget: VolumeUpIcon(size: 20, color: ink),
            ink: ink,
            onTap: () => onVolume(5),
          ),
          const SizedBox(height: 4),
          _StickBtn(
            key: const Key('media-tool-vol-down'),
            // Lucide volume-1 — Material volume_down ki jagah.
            iconWidget: VolumeDownIcon(size: 20, color: ink),
            ink: ink,
            onTap: () => onVolume(-5),
          ),
          const SizedBox(height: 4),
          _StickBtn(
            key: const Key('media-tool-shot'),
            // Lucide camera (lucide.dev) — Material camera ki jagah.
            // Ye screenshot button hai (neeche wala, camera icon).
            iconWidget: CameraIcon(size: 20, color: ink),
            ink: ink,
            onTap: onScreenshot,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

/// Stick ka ek tool button — 54×54, sirf icon.
class _StickBtn extends StatelessWidget {
  final IconData? icon;
  // Custom icon (jaise Lucide camera) — IconData ki jagah.
  final Widget? iconWidget;
  final Color ink;
  final VoidCallback onTap;

  const _StickBtn({
    super.key,
    this.icon,
    this.iconWidget,
    required this.ink,
    required this.onTap,
  }) : assert(icon != null || iconWidget != null);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 54,
          height: 54,
          // Center zaroori hai — baghair iske SizedBox (54x54)
          // CustomPaint icon ko 54x54 par force kar deta hai
          // (quick-tools stick wala bug). Center loose constraints
          // deta hai, to icon apni asli size (20) par banta hai.
          child: Center(
            child: iconWidget ?? Icon(icon, size: 24, color: ink),
          ),
        ),
      ),
    );
  }
}
