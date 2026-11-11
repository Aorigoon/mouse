import 'package:flutter/material.dart';

/// Rotate CW icon — Lucide "rotate-cw", lucide.dev se liya hua
/// official SVG. Source paths:
/// `M21 12a9 9 0 1 1-9-9c2.52 0 4.93 1 6.74 2.74L21 8`,
/// `M21 3v5h-5`.
///
/// Stroke Lucide ka default 2.0 hai. Media stick ka Forward 10s
/// button is se lagta hai — Material `forward_10_outlined` ki jagah.
/// (Lucide par "10" wala version nahi hai — ye gol teer hi hai.)
class RotateCwIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const RotateCwIcon({
    super.key,
    this.size = 22,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RotateCwPainter(color, strokeWidth),
    );
  }
}

class _RotateCwPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _RotateCwPainter(this.color, this.strokeWidth);

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

    // Gol teer — M21 12a9 9 0 1 1-9-9c2.52 0 4.93 1 6.74 2.74L21 8.
    final arc = Path()
      ..moveTo(21 * s, 12 * s)
      ..arcToPoint(
        o(12, 3),
        radius: Radius.circular(9 * s),
        largeArc: true,
        clockwise: true,
      )
      ..cubicTo(
        14.52 * s, 3 * s,
        16.93 * s, 4 * s,
        18.74 * s, 5.74 * s,
      )
      ..lineTo(21 * s, 8 * s);
    canvas.drawPath(arc, paint);

    // Teer ka sir (upar-right) — M21 3v5h-5.
    final head = Path()
      ..moveTo(21 * s, 3 * s)
      ..lineTo(21 * s, 8 * s)
      ..lineTo(16 * s, 8 * s);
    canvas.drawPath(head, paint);
  }

  @override
  bool shouldRepaint(_RotateCwPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
