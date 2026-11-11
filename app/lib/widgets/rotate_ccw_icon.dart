import 'package:flutter/material.dart';

/// Rotate CCW icon — Lucide "rotate-ccw", lucide.dev se liya hua
/// official SVG. Source paths:
/// `M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8`,
/// `M3 3v5h5`.
///
/// Stroke Lucide ka default 2.0 hai. Media stick ka Rewind 10s
/// button is se lagta hai — Material `replay_10_outlined` ki jagah.
/// (Lucide par "10" wala version nahi hai — ye gol teer hi hai.)
class RotateCcwIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const RotateCcwIcon({
    super.key,
    this.size = 22,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RotateCcwPainter(color, strokeWidth),
    );
  }
}

class _RotateCcwPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _RotateCcwPainter(this.color, this.strokeWidth);

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

    // Gol teer — M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8.
    final arc = Path()
      ..moveTo(3 * s, 12 * s)
      ..arcToPoint(
        o(12, 3),
        radius: Radius.circular(9 * s),
        largeArc: true,
        clockwise: false,
      )
      ..arcToPoint(
        o(5.26, 5.74),
        radius: Radius.circular(9.75 * s),
        clockwise: false,
      )
      ..lineTo(3 * s, 8 * s);
    canvas.drawPath(arc, paint);

    // Teer ka sir (upar-left) — M3 3v5h5.
    final head = Path()
      ..moveTo(3 * s, 3 * s)
      ..lineTo(3 * s, 8 * s)
      ..lineTo(8 * s, 8 * s);
    canvas.drawPath(head, paint);
  }

  @override
  bool shouldRepaint(_RotateCcwPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
