import 'package:flutter/material.dart';

/// Download icon — Zain ka diya hua Lucide "download" SVG (neeche
/// wala arrow + tray). Source SVG paths: `M12 15V3`,
/// `M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4`, `m7 10 5 5 5-5`.
/// SVG paths ko 24x24 viewBox me waisa hi banaya hai, round
/// caps/joins. Stroke Lucide ka default 2.0 hai (Zain ne kaha
/// "default 2 PX ... wo rakh"). Save karne ke liye lagta hai
/// (ShotPage header, "Save to gallery") — Material download/save
/// icon ki jagah yehi lagta hai.
class DownloadIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const DownloadIcon({
    super.key,
    this.size = 22,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DownloadPainter(color, strokeWidth),
    );
  }
}

class _DownloadPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _DownloadPainter(this.color, this.strokeWidth);

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

    // Arrow shaft — M12 15V3 (neeche se upar).
    canvas.drawLine(o(12, 15), o(12, 3), paint);

    // Arrowhead (chevron) — m7 10 5 5 5-5.
    final head = Path()
      ..moveTo(7 * s, 10 * s)
      ..lineTo(12 * s, 15 * s)
      ..lineTo(17 * s, 10 * s);
    canvas.drawPath(head, paint);

    // Tray — M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4
    // (dono corners clockwise arc, radius 2).
    final tray = Path()
      ..moveTo(21 * s, 15 * s)
      ..lineTo(21 * s, 19 * s)
      ..arcToPoint(
        o(19, 21),
        radius: Radius.circular(2 * s),
        clockwise: true,
      )
      ..lineTo(5 * s, 21 * s)
      ..arcToPoint(
        o(3, 19),
        radius: Radius.circular(2 * s),
        clockwise: true,
      )
      ..lineTo(3 * s, 15 * s);
    canvas.drawPath(tray, paint);
  }

  @override
  bool shouldRepaint(_DownloadPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
