import 'package:flutter/material.dart';

/// Close (X) icon — Lucide "x", lucide.dev se liya hua official
/// SVG. Source paths: `M18 6 6 18`, `m6 6 12 12`.
///
/// Stroke Lucide ka default 2.0 hai. Dono sticks ke band karne
/// wale X button (khuli hui stick ka trigger) is se lagte hain —
/// Material `close_rounded` ki jagah.
class CloseIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const CloseIcon({
    super.key,
    this.size = 22,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ClosePainter(color, strokeWidth),
    );
  }
}

class _ClosePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _ClosePainter(this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    // 24x24 viewBox — stroke-width Lucide default 2.0.
    final s = size.width / 24.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Offset o(double x, double y) => Offset(x * s, y * s);

    // X — M18 6 6 18 aur m6 6 12 12.
    canvas.drawLine(o(18, 6), o(6, 18), paint);
    canvas.drawLine(o(6, 6), o(18, 18), paint);
  }

  @override
  bool shouldRepaint(_ClosePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
