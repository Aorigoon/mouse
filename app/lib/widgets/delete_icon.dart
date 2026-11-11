import 'package:flutter/material.dart';

/// Delete icon — Lucide "delete" (backspace key, andar X), lucide.dev
/// se liya hua official SVG. Source paths:
/// `M10 5a2 2 0 0 0-1.344.519l-6.328 5.74a1 1 0 0 0 0 1.481l6.328
/// 5.741A2 2 0 0 0 10 19h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2z`,
/// `m12 9 6 6`, `m18 9-6 6`.
///
/// Stroke Lucide ka default 2.0 hai (Zain ne kaha "default 2 PX ...
/// wo rakh"). Quick-tools stick ka Clear (Backspace) tool is se
/// lagta hai — Material `backspace_rounded` ki jagah.
class DeleteIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const DeleteIcon({
    super.key,
    this.size = 22,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DeletePainter(color, strokeWidth),
    );
  }
}

class _DeletePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _DeletePainter(this.color, this.strokeWidth);

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

    // Backspace key — M10 5 ... z (saare arcs sweep 0 = counter-clockwise).
    final key = Path()
      ..moveTo(10 * s, 5 * s)
      ..arcToPoint(
        o(8.656, 5.519),
        radius: Radius.circular(2 * s),
        clockwise: false,
      )
      ..lineTo(2.328 * s, 11.259 * s)
      ..arcToPoint(
        o(2.328, 12.74),
        radius: Radius.circular(1 * s),
        clockwise: false,
      )
      ..lineTo(8.656 * s, 18.481 * s)
      ..arcToPoint(
        o(10, 19),
        radius: Radius.circular(2 * s),
        clockwise: false,
      )
      ..lineTo(20 * s, 19 * s)
      ..arcToPoint(
        o(22, 17),
        radius: Radius.circular(2 * s),
        clockwise: false,
      )
      ..lineTo(22 * s, 7 * s)
      ..arcToPoint(
        o(20, 5),
        radius: Radius.circular(2 * s),
        clockwise: false,
      )
      ..close();
    canvas.drawPath(key, paint);

    // X — m12 9 6 6 aur m18 9-6 6.
    canvas.drawLine(o(12, 9), o(18, 15), paint);
    canvas.drawLine(o(18, 9), o(12, 15), paint);
  }

  @override
  bool shouldRepaint(_DeletePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
