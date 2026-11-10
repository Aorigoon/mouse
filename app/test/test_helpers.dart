import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// sensors_plus ke EventChannels ko test me mock karo.
///
/// `ShakeDetector.start()` home screen par accelerometer stream kholta hai.
/// Test environment me us channel ki koi native implementation nahi hoti,
/// is liye `MissingPluginException` async error ban kar test fail kar deta
/// hai. Ye mock stream kabhi event nahi bhejta — shake test me nahi hota,
/// sirf render hota hai.
void mockSensorsForTest() {
  const channels = [
    'dev.fluttercommunity.plus/sensors/accelerometer',
    'dev.fluttercommunity.plus/sensors/gyroscope',
    'dev.fluttercommunity.plus/sensors/user_accelerometer',
    'dev.fluttercommunity.plus/sensors/magnetometer',
  ];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  // sensors_plus pehle MethodChannel se sampling period set karta hai,
  // phir EventChannel se stream kholta hai — dono mock chahiye.
  messenger.setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/sensors/method'),
    (call) async => null,
  );
  for (final name in channels) {
    messenger.setMockStreamHandler(
      EventChannel(name),
      MockStreamHandler.inline(onListen: (_, _) {}),
    );
  }
}

/// speech_to_text ka MethodChannel mock — test me mic nahi hota.
/// `initialize`/`listen` true dete hain, taaki chip par tap karne se
/// listening state render ho (asli pehchan test me nahi hoti).
void mockSpeechForTest() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugin.csdcorp.com/speech_to_text'),
    (MethodCall call) async {
      switch (call.method) {
        case 'initialize':
        case 'has_permission':
          return true;
        case 'listen':
          return true;
        case 'locales':
          return <Map<String, Object?>>[];
        case 'stop':
        case 'cancel':
          return null;
        default:
          return null;
      }
    },
  );
}

/// Test me asli fonts load karo — warna golden screenshot me text sirf
/// grey blocks aur icons khaali squares dikhte hain (flutter_test ka
/// default Ahem font). Fonts `test/fonts/` me rakhe hain, taaki GitHub
/// Actions par bhi yehi render mile.
Future<void> loadTestFonts() async {
  Future<ByteData> load(String path) async {
    final bytes = await File(path).readAsBytes();
    return ByteData.view(bytes.buffer);
  }

  final roboto = FontLoader('Roboto')
    ..addFont(load('test/fonts/Roboto-Regular.ttf'))
    ..addFont(load('test/fonts/Roboto-Medium.ttf'))
    ..addFont(load('test/fonts/Roboto-Bold.ttf'));
  final icons = FontLoader('MaterialIcons')
    ..addFont(load('test/fonts/MaterialIcons-Regular.otf'));
  // Composer/terminal monospace fields — asli phone par system ka
  // monospace font hota hai; test me Roboto usi naam se load karo
  // taaki text blocks na bane.
  final mono = FontLoader('monospace')
    ..addFont(load('test/fonts/Roboto-Regular.ttf'))
    ..addFont(load('test/fonts/Roboto-Bold.ttf'));
  await Future.wait([roboto.load(), icons.load(), mono.load()]);
}
