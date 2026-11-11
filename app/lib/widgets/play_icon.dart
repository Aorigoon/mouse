import 'package:flutter/material.dart';

/// Play icon — Lucide "play", lucide.dev se liya hua official SVG.
/// Source path:
/// `M5 5a2 2 0 0 1 3.008-1.728l11.997 6.998a2 2 0 0 1 .003
/// 3.458l-12 7A2 2 0 0 1 5 19z`.
///
/// Stroke Lucide ka default 2.0 hai. Media stick ka Play/Pause
/// button aur media stick ka trigger (band haalat me) is se lagte
/// hain — Material `play_arrow_rounded` ki jagah. (Outline triangle
/// hai — Material wala bhara hua triangle nahi.)
class PlayIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const PlayIcon({
    super.key,
    this.size = 22,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PlayPainter(color, strokeWidth),
    );
  }
}

class _PlayPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _PlayPainter(this.color, this.strokeWidth);

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

    // Play triangle (gol corners) — M5 5 ... z.
    final triangle = Path()
      ..moveTo(5 * s, 5 * s)
      ..arcToPoint(
        o(8.008, 3.272),
        radius: Radius.circular(2 * s),
        clockwise: true,
      )
      ..lineTo(20.005 * s, 10.27 * s)
      ..arcToPoint(
        o(20.008, 13.728),
        radius: Radius.circular(2 * s),
        clockwise: true,
      )
      ..lineTo(8.008 * s, 20.728 * s)
      ..arcToPoint(
        o(5, 19),
        radius: Radius.circular(2 * s),
        clockwise: true,
      )
      ..close();
    canvas.drawPath(triangle, paint);
  }

  @override
  bool shouldRepaint(_PlayPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
