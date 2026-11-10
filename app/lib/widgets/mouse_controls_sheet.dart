import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connection/settings_store.dart';
import '../theme.dart';

/// Three-dot se khulne wali Settings — Muse ki Settings page jaisi:
/// dark gray rounded card, rows with icon + label + chevron/switch.
/// - Mouse Speed: card ke andar hi snail–slider–rabbit (gradient
///   track, drag par value bubble) — koi alag page/sheet nahi.
/// - Motion Control yahin toggle hota hai; on ho to neeche uski
///   speed ka slider bhi aa jata hai.
/// Settings page wala sara ka sara edit yahan nahi; scroll/wheel/
/// double-tap wagera Settings tab me rehte hain.
Future<void> showMouseControlsSheet(BuildContext context) {
  HapticFeedback.selectionClick();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _MouseSettingsSheet(),
  );
}

class _MouseSettingsSheet extends StatelessWidget {
  const _MouseSettingsSheet();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    // Hamesha dark gray — flat matte, koi border line nahi.
    return Material(
      color: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: SafeArea(
          top: false,
          // Chhoti screens par sheet scroll ho — overflow error nahi.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Header: close + Settings
                SizedBox(
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceGray,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Card with rows
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGray,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mouse Speed — label + snail-slider-rabbit
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Row(
                          children: [
                            Icon(Icons.speed_rounded,
                                size: 22,
                                color:
                                    Colors.white.withValues(alpha: 0.85)),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                'Mouse Speed',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              settings.sensitivity.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: _SpeedSlider(),
                      ),
                      _RowDivider(),
                      _SettingsRow(
                        icon: Icons.screen_rotation_rounded,
                        label: 'Motion Control',
                        trailing: Switch(
                          value: settings.motionControl,
                          activeThumbColor: Colors.black,
                          activeTrackColor: AppColors.accent,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor:
                              Colors.white.withValues(alpha: 0.2),
                          onChanged: (v) {
                            settings.setMotionControl(v);
                            HapticFeedback.selectionClick();
                          },
                        ),
                      ),
                      if (settings.motionControl) ...[
                        _RowDivider(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Motion speed',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    settings.motionSensitivity
                                        .toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.royalBlue,
                                    ),
                                  ),
                                ],
                              ),
                              _BlueSlider(
                                value: settings.motionSensitivity,
                                min: 0.5,
                                max: 2.0,
                                divisions: 15,
                                onChanged: settings.setMotionSensitivity,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Card ke rows ke beech halki divider.
class _RowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 56),
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}

/// Ek settings row — icon + label + trailing (chevron ya switch).
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon,
                  size: 22, color: Colors.white.withValues(alpha: 0.85)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Royal blue slider — speed controls ke liye.
class _BlueSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _BlueSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: AppColors.royalBlue,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
        thumbColor: AppColors.royalBlue,
        overlayColor: AppColors.royalBlue.withValues(alpha: 0.15),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }
}

/// Snail — gradient slider — rabbit (Mouse Speed control).
///
/// Drag se speed badalti hai (0.5–3.0, 0.1 steps), value turant
/// lagti aur save hoti hai. Track par tap karo to thumb wahan
/// animate hokar jata hai. Drag karte waqt thumb ke upar value
/// wala bubble dikhta hai, chhorne ke thodi der baad gayab.
class _SpeedSlider extends StatefulWidget {
  const _SpeedSlider();

  @override
  State<_SpeedSlider> createState() => _SpeedSliderState();
}

class _SpeedSliderState extends State<_SpeedSlider>
    with SingleTickerProviderStateMixin {
  static const double _min = 0.5;
  static const double _max = 3.0;
  static const double _thumbRadius = 14.0;

  late final AnimationController _controller;
  bool _dragging = false;
  Timer? _hideTimer;
  double _lastApplied = -1;

  double get _progress => _controller.value;
  double get _sensitivity => _min + _progress * (_max - _min);

  @override
  void initState() {
    super.initState();
    final current = context.read<AppSettings>().sensitivity;
    final initial = ((current - _min) / (_max - _min)).clamp(0.0, 1.0);
    _controller = AnimationController(
      vsync: this,
      value: initial,
      duration: const Duration(milliseconds: 200),
    )..addListener(_onProgressChanged);
    _lastApplied = current;
  }

  void _onProgressChanged() {
    final snapped = (_sensitivity * 10).round() / 10;
    if (snapped != _lastApplied) {
      _lastApplied = snapped;
      context.read<AppSettings>().setSensitivity(snapped);
      HapticFeedback.selectionClick();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _showTooltip() {
    _hideTimer?.cancel();
    if (!_dragging) setState(() => _dragging = true);
  }

  void _scheduleHideTooltip() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _dragging = false);
    });
  }

  double _progressFromDx(double dx, double width) {
    final travel = width - 2 * _thumbRadius;
    if (travel <= 0) return 0;
    return ((dx - _thumbRadius) / travel).clamp(0.0, 1.0);
  }

  double _thumbX(double width) =>
      _thumbRadius + _progress * (width - 2 * _thumbRadius);

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('speed-slider'),
      children: [
        const SizedBox(
          width: 28,
          height: 28,
          child: CustomPaint(painter: _SnailPainter()),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final thumbX = _thumbX(width);
              // Tooltip thumb ke upar float karta hai — slider ki box se
              // bahar (is liye label aur track ke beech koi khaali jagah
              // nahi chhodni padti).
              final bubbleLeft =
                  (thumbX - 26).clamp(0.0, (width - 52).clamp(0.0, width));
              return SizedBox(
                height: 40,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Tooltip bubble — sirf drag karte waqt
                    Positioned(
                      top: -32,
                      left: bubbleLeft,
                      child: AnimatedOpacity(
                        opacity: _dragging ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 150),
                        child: AnimatedScale(
                          scale: _dragging ? 1.0 : 0.8,
                          duration: const Duration(milliseconds: 150),
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 52,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              _sensitivity.toStringAsFixed(1),
                              key: const Key('speed-tooltip'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Track + thumb (vertically centered — snail/rabbit
                    // icons bhi isi line par hain)
                    Positioned.fill(
                      child: GestureDetector(
                        key: const Key('speed-slider-track'),
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragStart: (_) => _showTooltip(),
                        onHorizontalDragUpdate: (details) {
                          _controller.value = _progressFromDx(
                            details.localPosition.dx,
                            width,
                          );
                        },
                        onHorizontalDragEnd: (_) => _scheduleHideTooltip(),
                        onTapDown: (details) {
                          _showTooltip();
                          _controller.animateTo(
                            _progressFromDx(details.localPosition.dx, width),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        onTapUp: (_) => _scheduleHideTooltip(),
                        child: CustomPaint(
                          painter: _SliderPainter(_progress),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 14),
        const SizedBox(
          width: 28,
          height: 28,
          child: CustomPaint(painter: _RabbitPainter()),
        ),
      ],
    );
  }
}

/// Gradient track + white thumb (video jaisa).
class _SliderPainter extends CustomPainter {
  final double progress;

  const _SliderPainter(this.progress);

  static const _thumbRadius = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    const h = 6.0;
    final track = RRect.fromLTRBR(
      0,
      cy - h / 2,
      size.width,
      cy + h / 2,
      const Radius.circular(3),
    );
    // Unfilled — halka gray
    canvas.drawRRect(
      track,
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
    // Filled — gradient (red → orange → yellow → green)
    final thumbX = _thumbRadius + progress * (size.width - 2 * _thumbRadius);
    if (thumbX > 0) {
      final fill = RRect.fromLTRBR(
        0,
        cy - h / 2,
        thumbX,
        cy + h / 2,
        const Radius.circular(3),
      );
      canvas.drawRRect(
        fill,
        Paint()
          ..shader = const LinearGradient(
            colors: [
              Color(0xFFFF3B30),
              Color(0xFFFF9500),
              Color(0xFFFFCC00),
              Color(0xFF7ED321),
              Color(0xFF34C759),
            ],
            stops: [0.0, 0.3, 0.55, 0.8, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    }
    // Thumb — white circle, halki shadow
    canvas.drawCircle(
      Offset(thumbX, cy + 2),
      _thumbRadius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      Offset(thumbX, cy),
      _thumbRadius,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _SliderPainter old) =>
      old.progress != progress;
}

/// Snail outline — slow side (video jaisa).
class _SnailPainter extends CustomPainter {
  const _SnailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Shell
    canvas.drawCircle(const Offset(11, 15), 7.5, paint);
    // Spiral
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(11, 15), radius: 3.5),
      0.6,
      4.2,
      false,
      paint,
    );
    // Foot
    final foot = Path()
      ..moveTo(3, 23)
      ..quadraticBezierTo(13, 20.5, 23, 23);
    canvas.drawPath(foot, paint);
    // Head + antennae
    canvas.drawLine(const Offset(21, 21.5), const Offset(21, 17), paint);
    canvas.drawLine(const Offset(21, 17), const Offset(18.5, 12.5), paint);
    canvas.drawLine(const Offset(21, 17), const Offset(23.5, 12.5), paint);
    // Antennae tips
    final dot = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(18.5, 12.5), 1.3, dot);
    canvas.drawCircle(const Offset(23.5, 12.5), 1.3, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Rabbit outline — fast side (video jaisa).
class _RabbitPainter extends CustomPainter {
  const _RabbitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Ears (lambi, seedhi)
    canvas.drawLine(const Offset(12, 13), const Offset(10, 3), paint);
    canvas.drawLine(const Offset(16, 13), const Offset(18, 3), paint);
    // Head
    canvas.drawCircle(const Offset(14, 19), 6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
