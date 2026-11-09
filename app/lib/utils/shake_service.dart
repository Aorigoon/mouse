import 'dart:async';
import 'dart:math';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Foreground service — app band ho (swipe away) tab bhi accelerometer
/// sunta rehta hai; shake hone par app wapas khol deta hai.
@pragma('vm:entry-point')
void mousifyServiceCallback() {
  FlutterForegroundTask.setTaskHandler(_ShakeServiceHandler());
}

class _ShakeServiceHandler extends TaskHandler {
  StreamSubscription? _sub;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _sub?.cancel();
    _sub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 60),
    ).listen(_onEvent);
  }

  void _onEvent(AccelerometerEvent e) {
    final mag = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    if (mag < 19) return;
    final now = DateTime.now();
    if (now.difference(_lastShake).inMilliseconds < 1500) return;
    _lastShake = now;
    // app foreground me lao (agar already foreground me hai to no-op)
    FlutterForegroundTask.launchApp();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isReboot) async {
    await _sub?.cancel();
    _sub = null;
  }
}
