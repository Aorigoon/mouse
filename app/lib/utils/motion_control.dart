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
/// - On karte hi pehle ~300ms me phone ki neutral position
///   (baseline) note hoti hai — uske baad us se zyada tilt
///   hote hi cursor chalna shuru.
/// - Halka tilt = bohot slow, zyada tilt = fast — quadratic
///   response, taaki chhota tilt bhi control me rahe aur cursor
///   corner par na bhaage. Full tilt par bhi max ~700px/s.
/// - Accelerometer ki noise ko low-pass filter se smooth kiya jata
///   hai, taaki haath ki halki kampan se cursor na kaanpe.
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
  double _baseSumX = 0;
  double _baseSumY = 0;
  int _calibrationSamples = 0;
  static const int _calibrationCount = 15;

  // Low-pass filter — accelerometer ki noise smooth karo.
  // alpha 0.3: ~3-4 readings me settle, haath ki kampan gayab.
  double _fx = 0;
  double _fy = 0;
  bool _filterInit = false;
  static const double _filterAlpha = 0.3;

  // Response — halka tilt slow, zyada tilt fast (quadratic).
  // Full tilt (4 m/s²) par max ~700px/s (sensitivity 1.0).
  static const double _deadZone = 0.8; // m/s² — haath ki kampan ignore
  static const double _maxTilt = 4.0; // m/s² — full tilt
  static const double _maxSpeedPxPerSec = 700.0;
  static const double _dt = 0.02; // 20ms sampling
  static const double _maxStepPx = 15.0; // per event safety clamp

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
    _baseSumX = 0;
    _baseSumY = 0;
    _filterInit = false;
    _fx = 0;
    _fy = 0;
    _sub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen(_onEvent, onError: (_) {});
  }

  void _onEvent(AccelerometerEvent e) {
    // Low-pass filter — pehli reading se init karo.
    if (!_filterInit) {
      _fx = e.x;
      _fy = e.y;
      _filterInit = true;
    } else {
      _fx += _filterAlpha * (e.x - _fx);
      _fy += _filterAlpha * (e.y - _fy);
    }

    // Pehle 15 readings se neutral position seekho (filtered).
    if (_calibrationSamples < _calibrationCount) {
      _baseSumX += _fx;
      _baseSumY += _fy;
      _calibrationSamples++;
      if (_calibrationSamples == _calibrationCount) {
        _baseX = _baseSumX / _calibrationCount;
        _baseY = _baseSumY / _calibrationCount;
      }
      return;
    }
    if (!_conn.isReady) return;

    // Neutral se deviation — dead zone ke andar halki harkat ignore.
    // Dead zone ke just upar bhi response chhota ho (smooth ramp).
    double devX = _fx - _baseX;
    double devY = _fy - _baseY;
    final effX = _effective(devX);
    final effY = _effective(devY);
    if (effX == 0 && effY == 0) return;

    // Quadratic response — chhota tilt bohot slow, bada tilt tez
    // (lekin max speed capped, cursor corner par nahi bhaagta).
    final maxSpeed = _maxSpeedPxPerSec * _settings.motionSensitivity;
    final dx = (-_speed(effX, maxSpeed) * _dt).clamp(
      -_maxStepPx,
      _maxStepPx,
    );
    final dy = (_speed(effY, maxSpeed) * _dt).clamp(
      -_maxStepPx,
      _maxStepPx,
    );
    if (dx == 0 && dy == 0) return;
    _conn.move(dx, dy);
  }

  /// Dead zone ke baad ka effective deviation (smooth ramp).
  double _effective(double dev) {
    final a = dev.abs();
    if (a < _deadZone) return 0;
    return dev.sign * (a - _deadZone);
  }

  /// Effective deviation (0.._maxTilt) ko px/s speed me badlo — quadratic.
  double _speed(double effective, double maxSpeed) {
    final t = (effective.abs() / _maxTilt).clamp(0.0, 1.0);
    return effective.sign * maxSpeed * t * t;
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  void dispose() => stop();
}
