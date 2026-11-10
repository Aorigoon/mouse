import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mousify/connection/server_connection.dart';
import 'package:mousify/connection/settings_store.dart';
import 'package:mousify/utils/motion_control.dart';

/// Fake connection — move() calls record karta hai, isReady hamesha true
/// (asli server ke baghair, taaki tilt logic test ho sake).
class _FakeConn extends MousifyConnection {
  final List<(double, double)> moves = [];

  @override
  bool get isReady => true;

  @override
  void move(double dx, double dy) => moves.add((dx, dy));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Accelerometer channel ka sink — is se synthetic tilt events bhejte hain.
  dynamic accelSink;

  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/sensors/method'),
      (call) async => null,
    );
    messenger.setMockStreamHandler(
      const EventChannel('dev.fluttercommunity.plus/sensors/accelerometer'),
      MockStreamHandler.inline(
        onListen: (_, events) {
          accelSink = events;
        },
      ),
    );
  });

  // Ek accelerometer reading bhejo (wire format: [x, y, z, timestamp]).
  Future<void> emit(double x, double y, [double z = 9.8]) async {
    accelSink?.success(<double>[x, y, z, 1000000.0]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  test('tilt se cursor move hota hai — calibration, dead zone, stop', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();
    await settings.loaded;
    settings.setMotionControl(true);

    final conn = _FakeConn();
    final controller = MotionController(conn: conn, settings: settings);
    controller.start();

    // Pehle 15 readings: phone seedha — neutral calibration, koi move nahi.
    for (var i = 0; i < 15; i++) {
      await emit(0.0, 0.0);
    }
    expect(conn.moves, isEmpty);

    // Halka tilt (dead zone 0.8 ke andar) — kuch nahi hona chahiye.
    await emit(0.2, 0.0);
    expect(conn.moves, isEmpty);

    // Right tilt (x +2.0) — filter ko settle hone do (5 readings),
    // phir cursor left jana chahiye (dx negative), aur slow hona
    // chahiye (purana 30px/event nahi — ab max ~14px/event).
    for (var i = 0; i < 5; i++) {
      await emit(2.0, 0.0);
    }
    expect(conn.moves, isNotEmpty);
    expect(conn.moves.last.$1, lessThan(0));
    expect(conn.moves.last.$1.abs(), lessThanOrEqualTo(15.0));

    // Forward tilt (y +2.0) — cursor neeche jana chahiye (dy positive).
    for (var i = 0; i < 5; i++) {
      await emit(0.0, 2.0);
    }
    expect(conn.moves.last.$2, greaterThan(0));

    // Strong tilt (x +5.0) — bhi capped hona chahiye, corner par
    // nahi bhaagna chahiye (per-event max 15px).
    for (var i = 0; i < 8; i++) {
      await emit(5.0, 0.0);
    }
    expect(conn.moves.last.$1.abs(), lessThanOrEqualTo(15.0));

    // Stop — uske baad tilt par kuch nahi hona chahiye.
    final count = conn.moves.length;
    controller.stop();
    await emit(2.0, 2.0);
    expect(conn.moves.length, count);

    controller.dispose();
  });
}
