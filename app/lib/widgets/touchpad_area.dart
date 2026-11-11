import 'dart:async';
import '../utils/haptics.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connection/server_connection.dart';
import '../connection/settings_store.dart';
import '../theme.dart';
import '../views/composer_page.dart';
import 'quick_tools_stick.dart';

/// Plain black touchpad:
///   • 1 finger drag          → cursor move
///   • 1 tap                  → left click
///   • double tap             → composer
///   • long-press + drag      → scroll (wheel)
///   • neeche ka button       → right click
class TouchpadArea extends StatefulWidget {
  const TouchpadArea({super.key});

  @override
  State<TouchpadArea> createState() => _TouchpadAreaState();
}

class _TouchpadAreaState extends State<TouchpadArea> {
  int? _pointer;
  Offset? _last;
  DateTime? _downTime;
  double _travel = 0;
  bool _moved = false;
  bool _scrollMode = false;

  Timer? _longPressTimer;
  Timer? _pendingClick;
  DateTime? _lastTapTime;

  double _residualX = 0;
  double _residualY = 0;
  double _scrollResidual = 0;

  final ValueNotifier<Offset?> _touch = ValueNotifier<Offset?>(null);
  final ValueNotifier<bool> _scrolling = ValueNotifier<bool>(false);

  static const _longPressMs = 320;
  static const _moveThreshold = 10.0;
  static const _tapWindowMs = 200;

  MousifyConnection _conn() => context.read<MousifyConnection>();

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _pendingClick?.cancel();
    _touch.dispose();
    _scrolling.dispose();
    super.dispose();
  }

  // ---- pointer handling ---------------------------------------------------
  void _onDown(PointerDownEvent e) {
    if (_pointer != null) return; // sirf ek finger
    _pointer = e.pointer;
    _last = e.localPosition;
    _downTime = DateTime.now();
    _travel = 0;
    _moved = false;
    _scrollMode = false;
    _touch.value = e.localPosition;

    _longPressTimer?.cancel();
    _longPressTimer = Timer(const Duration(milliseconds: _longPressMs), () {
      if (_pointer == null || _moved || _scrollMode) return;
      setState(() => _scrollMode = true);
      _scrolling.value = true;
      Haptics.impact();
    });
  }

  void _onMove(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    final last = _last;
    if (last == null) return;
    final delta = e.localPosition - last;
    _last = e.localPosition;
    _touch.value = e.localPosition;
    _travel += delta.distance;

    if (_scrollMode) {
      _pushScroll(delta.dy);
      return;
    }

    if (_travel > _moveThreshold) {
      _moved = true;
      _longPressTimer?.cancel();
    }
    if (!_moved) return;

    final scale = context.read<AppSettings>().sensitivity;
    _residualX += delta.dx * scale;
    _residualY += delta.dy * scale;
    final dx = _residualX.truncateToDouble();
    final dy = _residualY.truncateToDouble();
    _residualX -= dx;
    _residualY -= dy;
    if (dx != 0 || dy != 0) _conn().move(dx, dy);
  }

  void _onUp(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    final wasScroll = _scrollMode;
    final moved = _moved;
    final downTime = _downTime;
    final travel = _travel;

    _pointer = null;
    _last = null;
    _downTime = null;
    _travel = 0;
    _moved = false;
    _scrollMode = false;
    _scrolling.value = false;
    _longPressTimer?.cancel();
    _touch.value = null;

    if (wasScroll) return;

    final duration = downTime == null
        ? 9999
        : DateTime.now().difference(downTime).inMilliseconds;
    final isTap =
        !moved && travel < _moveThreshold && duration < _longPressMs;
    if (!isTap) return;

    final now = DateTime.now();
    final isDouble = _lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < _tapWindowMs;

    if (isDouble) {
      _pendingClick?.cancel();
      _pendingClick = null;
      _lastTapTime = null;
      Haptics.impact();
      _openComposer();
    } else {
      _lastTapTime = now;
      _pendingClick?.cancel();
      _pendingClick = Timer(const Duration(milliseconds: _tapWindowMs), () {
        Haptics.click();
        _conn().button('left', 'click');
        _lastTapTime = null;
      });
    }
  }

  void _onCancel(PointerCancelEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    _last = null;
    _downTime = null;
    _travel = 0;
    _moved = false;
    _scrollMode = false;
    _scrolling.value = false;
    _longPressTimer?.cancel();
    _touch.value = null;
  }

  void _pushScroll(double deltaDy) {
    final settings = context.read<AppSettings>();
    var dy = deltaDy * 0.12;
    if (settings.naturalScroll) dy = -dy;
    _scrollResidual += dy * settings.wheelSensitivity;
    final d = _scrollResidual.truncateToDouble();
    _scrollResidual -= d;
    if (d != 0) _conn().scroll(d);
  }

  void _openComposer() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ComposerPage()),
    );
  }

  void _rightClick() {
    Haptics.click();
    _conn().button('right', 'click');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _onDown,
            onPointerMove: _onMove,
            onPointerUp: _onUp,
            onPointerCancel: _onCancel,
            child: Container(
              // Theme surface — dark par black, light par white.
              color: scheme.surface,
              child: AnimatedBuilder(
                animation: Listenable.merge([_touch, _scrolling]),
                builder: (context, _) => CustomPaint(
                  painter: _TouchPainter(
                    touch: _touch.value,
                    scrolling: _scrolling.value,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 118,
          child: _RightClickButton(onTap: _rightClick),
        ),
        // Quick-tools stick — right-click button ke upar. Tap par
        // stick ki tarah seedha upar expand hoti hai (54 chaudi).
        const Positioned(
          right: 20,
          bottom: 184,
          child: QuickToolsStick(),
        ),
      ],
    );
  }
}

/// Touchpad dot grid — Zain ki reference image jaisi.
///
/// Finger dabao to poore touchpad par dots ki grid nazar aati hai:
/// finger ke qareeb dots bade aur gehre royal blue, bahar ki taraf
/// chhote aur halke — reference image se thode chhote. Finger uthe
/// to grid gayab (pad bilkul saaf). Background dark mode me pure
/// black rehta hai. Scroll mode ke up/down chevrons royal blue
/// rehte hain.
class _TouchPainter extends CustomPainter {
  final Offset? touch;
  final bool scrolling;

  const _TouchPainter({required this.touch, required this.scrolling});

  // Grid spacing aur dot size — reference image se thode chhote.
  static const _spacing = 26.0;
  static const _influence = 180.0;
  static const _minRadius = 1.0;
  static const _maxRadius = 3.5;
  static const _minAlpha = 0.10;
  static const _maxAlpha = 0.90;

  @override
  void paint(Canvas canvas, Size size) {
    final t = touch;
    if (t == null) return;

    // Grid — har point par dot; finger se doori se size aur alpha.
    for (var y = _spacing / 2; y < size.height; y += _spacing) {
      for (var x = _spacing / 2; x < size.width; x += _spacing) {
        final d = (Offset(x, y) - t).distance;
        var f = (1 - d / _influence).clamp(0.0, 1.0);
        f = f * f; // smooth falloff — center ke qareeb ghana
        final r = _minRadius + (_maxRadius - _minRadius) * f;
        final a = _minAlpha + (_maxAlpha - _minAlpha) * f;
        canvas.drawCircle(
          Offset(x, y),
          r,
          Paint()..color = AppColors.royalBlue.withValues(alpha: a),
        );
      }
    }

    if (scrolling) {
      final chevron = Paint()
        ..color = AppColors.royalBlue.withValues(alpha: 0.75)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      const s = 6.0;
      const gap = 22.0;
      canvas.drawPath(
        Path()
          ..moveTo(t.dx - s, t.dy - gap + s)
          ..lineTo(t.dx, t.dy - gap)
          ..lineTo(t.dx + s, t.dy - gap + s),
        chevron,
      );
      canvas.drawPath(
        Path()
          ..moveTo(t.dx - s, t.dy + gap - s)
          ..lineTo(t.dx, t.dy + gap)
          ..lineTo(t.dx + s, t.dy + gap - s),
        chevron,
      );
    }
  }

  @override
  bool shouldRepaint(_TouchPainter old) =>
      old.touch != touch || old.scrolling != scrolling;
}

class _RightClickButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RightClickButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Flat matte gray, chips jaisa — koi border line, koi shadow nahi.
        color: AppColors.raised(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 54,
            height: 54,
            child: Icon(
              Icons.ads_click_rounded,
              color: AppColors.ink(isDark),
              size: 23,
            ),
          ),
        ),
      ),
    );
  }
}
