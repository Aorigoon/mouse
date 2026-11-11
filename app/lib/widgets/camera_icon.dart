import 'package:flutter/material.dart';

/// Camera icon — Lucide "camera", lucide.dev se liya hua official
/// SVG. Source path:
/// `M13.997 4a2 2 0 0 1 1.76 1.05l.486.9A2 2 0 0 0 18.003 7H20a2
/// 2 0 0 1 2 2v9a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h1.997a2
/// 2 0 0 0 1.759-1.048l.489-.904A2 2 0 0 1 10.004 4z`,
/// aur lens circle `cx=12 cy=13 r=3`.
///
/// Stroke Lucide ka default 2.0 hai. Media stick ka Screenshot
/// button is se lagta hai — Material `photo_camera_outlined` ki
/// jagah.
class CameraIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const CameraIcon({
    super.key,
    this.size = 22,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CameraPainter(color, strokeWidth),
    );
  }
}

class _CameraPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _CameraPainter(this.color, this.strokeWidth);

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

    // Camera body — M13.997 4 ... z.
    final body = Path()
      ..moveTo(13.997 * s, 4 * s)
      ..arcToPoint(
        o(15.757, 5.05),
        radius: Radius.circular(2 * s),
        clockwise: true,
      )
      ..lineTo(16.243 * s, 5.95 * s)
      ..arcToPoint(
        o(18.003, 7),
        radius: Radius.circular(2 * s),
        clockwise: false,
      )
      ..lineTo(20 * s, 7 * s)
      ..arcToPoint(
        o(22, 9),
        radius: Radius.circular(2 * s),
        clockwise: true,
      )
      ..lineTo(22 * s, 18 * s)
      ..arcToPoint(
        o(20, 20),
        radius: Radius.circular(2 * s),
        clockwise: true,
      )
      ..lineTo(4 * s, 20 * s)
      ..arcToPoint(
        o(2, 18),
        radius: Radius.circular(2 * s),
        clockwise: true,
      )
      ..lineTo(2 * s, 9 * s)
      ..arcToPoint(
        o(4, 7),
        radius: Radius.circular(2 * s),
        clockwise: true,
      )
      ..lineTo(5.997 * s, 7 * s)
      ..arcToPoint(
        o(7.756, 5.952),
        radius: Radius.circular(2 * s),
        clockwise: false,
      )
      ..lineTo(8.245 * s, 5.048 * s)
      ..arcToPoint(
        o(10.004, 4),
        radius: Radius.circular(2 * s),
        clockwise: true,
      )
      ..close();
    canvas.drawPath(body, paint);

    // Lens — circle cx12 cy13 r3.
    canvas.drawCircle(o(12, 13), 3 * s, paint);
  }

  @override
  bool shouldRepaint(_CameraPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
