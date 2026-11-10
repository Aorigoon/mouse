import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Bottom nav "Apps" tab ka icon — Zain ki di hui reference image jaisa:
/// gol-chaukor outline ke andar 2x2 grid — teen squircle aur upar-right
/// wala diamond (45° ghuma hua chaukor).
///
/// Material ka `Icons.apps_rounded` (3x3 dots) is se match nahi karta,
/// is liye ye custom painter hai — nav ke active (black on white pill)
/// aur inactive (halka ink) dono states me `color` se chalta hai.
class AppsGridIcon extends StatelessWidget {
  final double size;
  final Color color;

  const AppsGridIcon({super.key, this.size = 22, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _AppsGridPainter(color),
    );
  }
}

class _AppsGridPainter extends CustomPainter {
  final Color color;

  _AppsGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // 24x24 viewBox — nav me 22px par render hota hai.
    final s = size.width / 24.0;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * s;

    // Bahar wala gol-chaukor outline.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1.6 * s, 1.6 * s, 20.8 * s, 20.8 * s),
        Radius.circular(6 * s),
      ),
      stroke,
    );

    // Andar 2x2 grid: cell 6.5, gap 2, area 4.6..19.4.
    const cell = 6.5;
    const gap = 2.0;
    const start = 4.6;
    RRect squircle(double x, double y) => RRect.fromRectAndRadius(
          Rect.fromLTWH(x * s, y * s, cell * s, cell * s),
          Radius.circular(2 * s),
        );

    // Upar-left squircle.
    canvas.drawRRect(squircle(start, start), fill);
    // Upar-right diamond — side cell/√2 taaki uska diagonal cell
    // ke barabar rahe (warna ghumane par chaukor se bada lagta hai).
    final diamondSide = cell / math.sqrt2;
    canvas.save();
    canvas.translate(
      (start + gap + cell + cell / 2) * s,
      (start + cell / 2) * s,
    );
    canvas.rotate(math.pi / 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -diamondSide / 2 * s,
          -diamondSide / 2 * s,
          diamondSide * s,
          diamondSide * s,
        ),
        Radius.circular(1.3 * s),
      ),
      fill,
    );
    canvas.restore();
    // Neeche-left aur neeche-right squircle.
    canvas.drawRRect(squircle(start, start + gap + cell), fill);
    canvas.drawRRect(
      squircle(start + gap + cell, start + gap + cell),
      fill,
    );
  }

  @override
  bool shouldRepaint(_AppsGridPainter oldDelegate) =>
      oldDelegate.color != color;
}
