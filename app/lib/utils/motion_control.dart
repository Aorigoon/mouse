import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import '../connection/server_connection.dart';
import '../connection/settings_store.dart';

/// Motion Control — phone tilt se cursor move.
///
/// Phone ko aage-peeche ya left-right tilt karo, cursor usi taraf
/// move hoga — jaise joystick. Accelerometer se gravity ka tilt
/// napa jata hai, is liye phone seedha pakdo ya flat rakho,
/// dono tarah kaam karta hai.
///
/// Kaise kaam karta hai:
/// - On karte hi pehle ~200ms me phone ki neutral position
///   (baseline) note hoti hai — uske baad us se zyada tilt
///   hote hi cursor chalna shuru.
/// - Halka tilt = slow, zyada tilt = fast. Seedha karte hi ruk jata hai.
/// - Cursor ko wahi 'move' event bhejta hai jo touchpad bhejta hai,
///   is liye server me koi change nahi chahiye.
/// - Android me accelerometer/gyroscope ke liye alag runtime
///   permission nahi hoti — sheet ka toggle hi on/off hai.
class MotionController {
  MotionController({
    required MousifyConnection conn,
    required AppSettings settings,
  })  : _conn = conn,
        _settings = settings;

  final MousifyConnection _conn;
  final AppSettings _settings;

  StreamSubscription<AccelerometerEvent>? _sub;

  // Neutral position — on karte waqt calibrate hoti hai.
  double _baseX = 0;
  double _baseY = 0;
  int _calibrationSamples = 0;
  static const int _calibrationCount = 10;

  /// Settings se sync — toggle on ho to start, off ho to stop.
  void sync() {
    if (_settings.motionControl) {
      start();
    } else {
      stop();
    }
  }

  void start() {
    if (_sub != null) return;
    _calibrationSamples = 0;
    _baseX = 0;
    _baseY = 0;
    _sub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen(_onEvent, onError: (_) {});
  }

  void _onEvent(AccelerometerEvent e) {
    // Pehle 10 readings se neutral position seekho.
    if (_calibrationSamples < _calibrationCount) {
      _baseX += e.x / _calibrationCount;
      _baseY += e.y / _calibrationCount;
      _calibrationSamples++;
      return;
    }
    if (!_conn.isReady) return;

    // Neutral se deviation — dead zone ke andar halki harkat ignore.
    const deadZone = 0.5; // m/s² — haath ki halki kampan ignore
    double devX = e.x - _baseX;
    double devY = e.y - _baseY;
    if (devX.abs() < deadZone) devX = 0;
    if (devY.abs() < deadZone) devY = 0;
    if (devX == 0 && devY == 0) return;

    // Tilt jitna zyada, cursor utna tez. 1 m/s² deviation ≈
    // 15px per event (~750px/s) — motionSensitivity se adjust.
    final k = 15.0 * _settings.motionSensitivity;
    final dx = (-devX * k).clamp(-30.0, 30.0);
    final dy = (devY * k).clamp(-30.0, 30.0);
    if (dx == 0 && dy == 0) return;
    _conn.move(dx, dy);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  void dispose() => stop();
}
