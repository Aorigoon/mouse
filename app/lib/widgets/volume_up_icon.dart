import 'package:flutter/material.dart';

/// Volume up icon — Lucide "volume-2", lucide.dev se liya hua
/// official SVG. Source paths: speaker
/// `M11 4.702a.705.705 0 0 0-1.203-.498L6.413 7.587A1.4 1.4 0 0 1
/// 5.416 8H3a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1h2.416a1.4 1.4 0 0 1
/// .997.413l3.383 3.384A.705.705 0 0 0 11 19.298z`,
/// andar wali lehar `M16 9a5 5 0 0 1 0 6`,
/// bahar wali lehar `M19.364 18.364a9 9 0 0 0 0-12.728`.
///
/// Stroke Lucide ka default 2.0 hai. Media stick ka Volume up
/// button is se lagta hai — Material `volume_up_rounded` ki jagah.
class VolumeUpIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const VolumeUpIcon({
    super.key,
    this.size = 22,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _VolumeUpPainter(color, strokeWidth),
    );
  }
}

class _VolumeUpPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _VolumeUpPainter(this.color, this.strokeWidth);

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

    // Speaker — M11 4.702 ... z.
    final speaker = Path()
      ..moveTo(11 * s, 4.702 * s)
      ..arcToPoint(
        o(9.797, 4.204),
        radius: Radius.circular(0.705 * s),
        clockwise: false,
      )
      ..lineTo(6.413 * s, 7.587 * s)
      ..arcToPoint(
        o(5.416, 8),
        radius: Radius.circular(1.4 * s),
        clockwise: true,
      )
      ..lineTo(3 * s, 8 * s)
      ..arcToPoint(
        o(2, 9),
        radius: Radius.circular(1 * s),
        clockwise: false,
      )
      ..lineTo(2 * s, 15 * s)
      ..arcToPoint(
        o(3, 16),
        radius: Radius.circular(1 * s),
        clockwise: false,
      )
      ..lineTo(5.416 * s, 16 * s)
      ..arcToPoint(
        o(6.413, 16.413),
        radius: Radius.circular(1.4 * s),
        clockwise: true,
      )
      ..lineTo(9.796 * s, 19.797 * s)
      ..arcToPoint(
        o(11, 19.298),
        radius: Radius.circular(0.705 * s),
        clockwise: false,
      )
      ..close();
    canvas.drawPath(speaker, paint);

    // Andar wali lehar — M16 9a5 5 0 0 1 0 6.
    final inner = Path()
      ..moveTo(16 * s, 9 * s)
      ..arcToPoint(
        o(16, 15),
        radius: Radius.circular(5 * s),
        clockwise: true,
      );
    canvas.drawPath(inner, paint);

    // Bahar wali lehar — M19.364 18.364a9 9 0 0 0 0-12.728.
    final outer = Path()
      ..moveTo(19.364 * s, 18.364 * s)
      ..arcToPoint(
        o(19.364, 5.636),
        radius: Radius.circular(9 * s),
        clockwise: false,
      );
    canvas.drawPath(outer, paint);
  }

  @override
  bool shouldRepaint(_VolumeUpPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
