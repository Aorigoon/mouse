import 'package:flutter/material.dart';

/// Copy icon — Zain ka diya hua Lucide "copy" SVG (do overlapping
/// rounded rectangles, peeche wala khula). Source SVG:
/// `<rect width="14" height="14" x="8" y="8" rx="2" ry="2"/>` aur
/// `<path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/>`.
/// SVG paths ko 24x24 viewBox me waisa hi banaya hai, round
/// caps/joins. Stroke Lucide ka default 2.0 hai (Zain ne kaha
/// "default 2 PX ... wo rakh"). Ye icon app me HAR jagah lagta hai
/// jahan pehle copy icon tha: ShotPage header, Composer actions
/// sheet ("Copy"), aur quick-tools stick ka Copy tool. `color` se
/// chalta hai (ShotPage par safed, baaki jagah ink).
class CopyIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const CopyIcon({
    super.key,
    this.size = 22,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CopyPainter(color, strokeWidth),
    );
  }
}

class _CopyPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _CopyPainter(this.color, this.strokeWidth);

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

    // Aage wala rectangle — x8 y8, 14x14, radius 2.
    final front = RRect.fromRectAndRadius(
      Rect.fromLTWH(8 * s, 8 * s, 14 * s, 14 * s),
      Radius.circular(2 * s),
    );
    canvas.drawRRect(front, paint);

    // Peeche wala rectangle (khula — neeche-right se jahan aage
    // wala overlap karta hai): M4 16 c-1.1 0-2-.9-2-2 V4
    // c0-1.1.9-2 2-2 h10 c1.1 0 2 .9 2 2
    final back = Path()
      ..moveTo(4 * s, 16 * s)
      ..cubicTo(2.9 * s, 16 * s, 2 * s, 15.1 * s, 2 * s, 14 * s)
      ..lineTo(2 * s, 4 * s)
      ..cubicTo(2 * s, 2.9 * s, 2.9 * s, 2 * s, 4 * s, 2 * s)
      ..lineTo(14 * s, 2 * s)
      ..cubicTo(15.1 * s, 2 * s, 16 * s, 2.9 * s, 16 * s, 4 * s);
    canvas.drawPath(back, paint);
  }

  @override
  bool shouldRepaint(_CopyPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
