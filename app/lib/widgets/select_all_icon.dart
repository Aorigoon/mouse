import 'package:flutter/material.dart';

/// Select All icon — Lucide "square-dashed", lucide.dev se liya
/// hua official SVG. (Lucide par "box-select" naam ka icon nahi
/// hai — 404 — is liye dashed square wala ye icon liya hai, jo
/// selection ko dikhata hai.) Source paths: 4 corners
/// `M5 3a2 2 0 0 0-2 2`, `M19 3a2 2 0 0 1 2 2`,
/// `M21 19a2 2 0 0 1-2 2`, `M5 21a2 2 0 0 1-2-2`, aur 8 dashes
/// `M9 3h1`, `M9 21h1`, `M14 3h1`, `M14 21h1`,
/// `M3 9v1`, `M21 9v1`, `M3 14v1`, `M21 14v1`.
///
/// Stroke Lucide ka default 2.0 hai. Quick-tools stick ka Select
/// All button is se lagta hai — Material `select_all_rounded` ki
/// jagah.
class SelectAllIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const SelectAllIcon({
    super.key,
    this.size = 22,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SelectAllPainter(color, strokeWidth),
    );
  }
}

class _SelectAllPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _SelectAllPainter(this.color, this.strokeWidth);

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

    // Corners — M5 3a2 2 0 0 0-2 2, M19 3a2 2 0 0 1 2 2,
    // M21 19a2 2 0 0 1-2 2, M5 21a2 2 0 0 1-2-2.
    final topLeft = Path()
      ..moveTo(5 * s, 3 * s)
      ..arcToPoint(
        o(3, 5),
        radius: Radius.circular(2 * s),
        clockwise: false,
      );
    canvas.drawPath(topLeft, paint);
    final topRight = Path()
      ..moveTo(19 * s, 3 * s)
      ..arcToPoint(
        o(21, 5),
        radius: Radius.circular(2 * s),
        clockwise: true,
      );
    canvas.drawPath(topRight, paint);
    final bottomRight = Path()
      ..moveTo(21 * s, 19 * s)
      ..arcToPoint(
        o(19, 21),
        radius: Radius.circular(2 * s),
        clockwise: true,
      );
    canvas.drawPath(bottomRight, paint);
    final bottomLeft = Path()
      ..moveTo(5 * s, 21 * s)
      ..arcToPoint(
        o(3, 19),
        radius: Radius.circular(2 * s),
        clockwise: true,
      );
    canvas.drawPath(bottomLeft, paint);

    // Dashes — upar/neeche (M9 3h1, M14 3h1, M9 21h1, M14 21h1)
    // aur sides (M3 9v1, M21 9v1, M3 14v1, M21 14v1).
    canvas.drawLine(o(9, 3), o(10, 3), paint);
    canvas.drawLine(o(14, 3), o(15, 3), paint);
    canvas.drawLine(o(9, 21), o(10, 21), paint);
    canvas.drawLine(o(14, 21), o(15, 21), paint);
    canvas.drawLine(o(3, 9), o(3, 10), paint);
    canvas.drawLine(o(21, 9), o(21, 10), paint);
    canvas.drawLine(o(3, 14), o(3, 15), paint);
    canvas.drawLine(o(21, 14), o(21, 15), paint);
  }

  @override
  bool shouldRepaint(_SelectAllPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
