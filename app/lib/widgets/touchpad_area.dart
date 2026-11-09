import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connection/server_connection.dart';
import '../connection/settings_store.dart';
import '../views/composer_page.dart';

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
      HapticFeedback.mediumImpact();
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
      HapticFeedback.mediumImpact();
      _openComposer();
    } else {
      _lastTapTime = now;
      _pendingClick?.cancel();
      _pendingClick = Timer(const Duration(milliseconds: _tapWindowMs), () {
        HapticFeedback.selectionClick();
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
    HapticFeedback.selectionClick();
    _conn().button('right', 'click');
  }

  @override
  Widget build(BuildContext context) {
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
              color: Colors.black,
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
          bottom: 20,
          child: _RightClickButton(onTap: _rightClick),
        ),
      ],
    );
  }
}

/// Finger ke neeche halka glow + dot + chhoti line.
class _TouchPainter extends CustomPainter {
  final Offset? touch;
  final bool scrolling;

  const _TouchPainter({required this.touch, required this.scrolling});

  @override
  void paint(Canvas canvas, Size size) {
    final t = touch;
    if (t == null) return;

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: scrolling ? 0.16 : 0.09),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: t, radius: 70));
    canvas.drawCircle(t, 70, glow);

    canvas.drawCircle(
      t,
      4.5,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(t.dx - 14, t.dy),
      Offset(t.dx + 14, t.dy),
      line,
    );

    if (scrolling) {
      final chevron = Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
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
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 54,
          height: 54,
          child: Icon(
            Icons.ads_click,
            color: Colors.white70,
            size: 23,
          ),
        ),
      ),
    );
  }
}
