import 'package:flutter/material.dart';

/// Undo icon — Lucide "undo-2", lucide.dev se liya hua official
/// SVG. Source paths: `M9 14 4 9l5-5`,
/// `M4 9h10.5a5.5 5.5 0 0 1 5.5 5.5a5.5 5.5 0 0 1-5.5 5.5H11`.
///
/// Stroke Lucide ka default 2.0 hai. Quick-tools stick ka Undo
/// button is se lagta hai — Material `undo_rounded` ki jagah.
class UndoIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const UndoIcon({
    super.key,
    this.size = 22,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _UndoPainter(color, strokeWidth),
    );
  }
}

class _UndoPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _UndoPainter(this.color, this.strokeWidth);

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

    // Teer ka sir — M9 14 4 9l5-5.
    final head = Path()
      ..moveTo(9 * s, 14 * s)
      ..lineTo(4 * s, 9 * s)
      ..lineTo(9 * s, 4 * s);
    canvas.drawPath(head, paint);

    // Ghuma hua teer — M4 9h10.5a5.5 5.5 0 0 1 5.5 5.5
    // a5.5 5.5 0 0 1-5.5 5.5H11.
    final curve = Path()
      ..moveTo(4 * s, 9 * s)
      ..lineTo(14.5 * s, 9 * s)
      ..arcToPoint(
        o(20, 14.5),
        radius: Radius.circular(5.5 * s),
        clockwise: true,
      )
      ..arcToPoint(
        o(14.5, 20),
        radius: Radius.circular(5.5 * s),
        clockwise: true,
      )
      ..lineTo(11 * s, 20 * s);
    canvas.drawPath(curve, paint);
  }

  @override
  bool shouldRepaint(_UndoPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
