import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Phone shake detect karta hai — accelerometer magnitude spike se.
/// Shake → mouse page wapas (jahan se bhi ho, composer band karke).
class ShakeDetector {
  ShakeDetector({
    required this.onShake,
    this.threshold = 18.0,
    this.cooldown = const Duration(milliseconds: 900),
  });

  final VoidCallback onShake;
  final double threshold; // m/s² — gravity (~9.8) se upar ka spike
  final Duration cooldown;

  StreamSubscription<AccelerometerEvent>? _sub;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);

  void start() {
    _sub ??= accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen(_onEvent);
  }

  void _onEvent(AccelerometerEvent e) {
    final mag = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    if (mag < threshold) return;
    final now = DateTime.now();
    if (now.difference(_lastShake) < cooldown) return;
    _lastShake = now;
    HapticFeedback.mediumImpact();
    onShake();
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }
}
