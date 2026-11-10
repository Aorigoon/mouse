import 'package:flutter/material.dart';

/// Bottom nav "Tools" tab ka icon — Zain ka diya hua Lucide toolbox SVG:
/// handle wala dabba, beech me horizontal line, andar do vertical lines.
///
/// SVG paths ko 24x24 viewBox me waisa hi banaya hai (stroke-width 2,
/// round caps/joins) — `Icons.handyman_rounded` is se match nahi karta,
/// is liye ye custom painter hai. Nav ke active (black on white pill)
/// aur inactive (halka ink) dono states me `color` se chalta hai.
class ToolboxIcon extends StatelessWidget {
  final double size;
  final Color color;

  const ToolboxIcon({super.key, this.size = 22, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ToolboxPainter(color),
    );
  }
}

class _ToolboxPainter extends CustomPainter {
  final Color color;

  _ToolboxPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // 24x24 viewBox — nav me 22px par render hota hai.
    final s = size.width / 24.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Offset o(double x, double y) => Offset(x * s, y * s);

    // Handle — M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2
    // (dono corners counterclockwise arc, radius 2).
    final handle = Path()
      ..moveTo(16 * s, 6 * s)
      ..lineTo(16 * s, 4 * s)
      ..arcToPoint(
        o(14, 2),
        radius: Radius.circular(2 * s),
        clockwise: false,
      )
      ..lineTo(10 * s, 2 * s)
      ..arcToPoint(
        o(8, 4),
        radius: Radius.circular(2 * s),
        clockwise: false,
      )
      ..lineTo(8 * s, 6 * s);
    canvas.drawPath(handle, paint);

    // Dabba — M17 6a2 2 0 011.414.586l3 3A2 2 0 0122 11v8a2 2 0 01-2 2H4a2 2 0 01-2-2v-8a2 2 0 01.586-1.414l3-3A2 2 0 017 6z
    // (saare corners clockwise arc, radius 2; upar wali edge close se).
    final box = Path()
      ..moveTo(17 * s, 6 * s)
      ..arcToPoint(
        o(18.414, 6.586),
        radius: Radius.circular(2 * s),
        clockwise: true,
      )
      ..lineTo(21.414 * s, 9.586 * s)
      ..arcToPoint(
        o(22, 11),
        radius: Radius.circular(2 * s),
        clockwise: true,
      )
      ..lineTo(22 * s, 19 * s)
      ..arcToPoint(
        o(20, 21),
        radius: Radius.circular(2 * s),
        clockwise: true,
      )
      ..lineTo(4 * s, 21 * s)
      ..arcToPoint(
        o(2, 19),
        radius: Radius.circular(2 * s),
        clockwise: true,
      )
      ..lineTo(2 * s, 11 * s)
      ..arcToPoint(
        o(2.586, 9.586),
        radius: Radius.circular(2 * s),
        clockwise: true,
      )
      ..lineTo(5.586 * s, 6.586 * s)
      ..arcToPoint(
        o(7, 6),
        radius: Radius.circular(2 * s),
        clockwise: true,
      )
      ..close();
    canvas.drawPath(box, paint);

    // Beech wali horizontal line — M2 14h20
    canvas.drawLine(o(2, 14), o(22, 14), paint);
    // Andar wali do vertical lines — M16 12v4, M8 12v4
    canvas.drawLine(o(16, 12), o(16, 16), paint);
    canvas.drawLine(o(8, 12), o(8, 16), paint);
  }

  @override
  bool shouldRepaint(_ToolboxPainter oldDelegate) =>
      oldDelegate.color != color;
}
