import 'package:flutter/material.dart';

import '../theme.dart';

/// Composer page wala back button — khud banaya hua arrow (CustomPaint),
/// koi stock icon nahi. 48x48 gol chip (AppColors.chip) ke andar
/// haath se bana arrow: "(" curve (tip) + peeche shaft line.
/// Legal pages (Terms/Privacy/FAQ/About) par bhi yahi lagta hai.
class BackChip extends StatelessWidget {
  final VoidCallback onTap;

  const BackChip({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: AppColors.chip(isDark),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: CustomPaint(
              size: const Size(30, 24),
              painter: BackArrowPainter(ink),
            ),
          ),
        ),
      ),
    );
  }
}

/// Haath se bana back arrow — "(" curve + shaft line, stroke 3,
/// round caps. Composer page ke Enter button me bhi yahi use hota
/// hai (90° ghuma kar, upar ki taraf).
class BackArrowPainter extends CustomPainter {
  final Color color;

  BackArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    // Arrow ko thoda aage (left) karo — pehle glyph circle ke center se
    // ~3.5px right (peeche) tha; 5px left shift se front aage aa jata hai.
    canvas.translate(-5, 0);
    // "(" curve — arrow ka tip, pehle jitna hi rounded aur utna hi size.
    // (Fixed coordinates taaki canvas chauda karne se curve na badhe.)
    final head = Path()
      ..moveTo(16.9, 2)
      ..quadraticBezierTo(1.04, size.height / 2, 16.9, size.height - 2);
    canvas.drawPath(head, paint);
    // Piche choti si line — arrow ki shaft, tip se right ki taraf.
    // Tip curve ka leftmost point hai (~8.97).
    canvas.drawLine(
      Offset(8.97, size.height / 2),
      Offset(size.width - 2, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant BackArrowPainter old) => old.color != color;
}
