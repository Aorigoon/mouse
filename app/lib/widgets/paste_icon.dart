import 'package:flutter/material.dart';

/// Paste icon — Lucide "clipboard-paste", lucide.dev se liya hua
/// official SVG. Source paths:
/// `M11 14h10`, `M16 4h2a2 2 0 0 1 2 2v1.344`,
/// `m17 18 4-4-4-4`, `M8 4H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2
/// 2 0 0 0 1.793-1.113`, aur rect `x=8 y=2 width=8 height=4 rx=1`.
///
/// Stroke Lucide ka default 2.0 hai (Zain ne kaha "default 2 PX ...
/// wo rakh"). Quick-tools stick ka Paste (Ctrl+V) tool is se
/// lagta hai — Material `content_paste_rounded` ki jagah.
class PasteIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const PasteIcon({
    super.key,
    this.size = 22,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PastePainter(color, strokeWidth),
    );
  }
}

class _PastePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _PastePainter(this.color, this.strokeWidth);

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

    // Clipboard ka clip (upar) — rect x8 y2 8x4, radius 1.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8 * s, 2 * s, 8 * s, 4 * s),
        Radius.circular(1 * s),
      ),
      paint,
    );

    // Clipboard body — M8 4H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2
    // 2 0 0 0 1.793-1.113 (neeche-right corner khula — arrow ke liye).
    final body = Path()
      ..moveTo(8 * s, 4 * s)
      ..lineTo(6 * s, 4 * s)
      ..arcToPoint(
        o(4, 6),
        radius: Radius.circular(2 * s),
        clockwise: false,
      )
      ..lineTo(4 * s, 20 * s)
      ..arcToPoint(
        o(6, 22),
        radius: Radius.circular(2 * s),
        clockwise: false,
      )
      ..lineTo(18 * s, 22 * s)
      ..arcToPoint(
        o(19.793, 20.887),
        radius: Radius.circular(2 * s),
        clockwise: false,
      );
    canvas.drawPath(body, paint);

    // Upar-right corner — M16 4h2a2 2 0 0 1 2 2v1.344
    // (arc sweep 1 = clockwise).
    final corner = Path()
      ..moveTo(16 * s, 4 * s)
      ..lineTo(18 * s, 4 * s)
      ..arcToPoint(
        o(20, 6),
        radius: Radius.circular(2 * s),
        clockwise: true,
      )
      ..lineTo(20 * s, 7.344 * s);
    canvas.drawPath(corner, paint);

    // Paste arrow — M11 14h10 + arrowhead m17 18 4-4-4-4.
    canvas.drawLine(o(11, 14), o(21, 14), paint);
    final head = Path()
      ..moveTo(17 * s, 18 * s)
      ..lineTo(21 * s, 14 * s)
      ..lineTo(17 * s, 10 * s);
    canvas.drawPath(head, paint);
  }

  @override
  bool shouldRepaint(_PastePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
