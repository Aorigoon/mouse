import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnState { disconnected, connecting, connected }

/// Jab tak connection ban na jaye (ya timeout ho) wait karta hai.
/// QR scan / manual connect ke baad feedback ke liye.
Future<bool> waitForConnection(
  MousifyConnection conn, {
  Duration timeout = const Duration(seconds: 10),
}) {
  if (conn.isReady) return Future.value(true);
  final completer = Completer<bool>();
  void listener() {
    if (conn.isReady && !completer.isCompleted) completer.complete(true);
  }

  conn.addListener(listener);
  final timer = Timer(timeout, () {
    if (!completer.isCompleted) completer.complete(false);
  });
  return completer.future.then((ok) {
    timer.cancel();
    conn.removeListener(listener);
    return ok;
  });
}

/// PC ke Mousify server se WebSocket connection — auto-reconnect ke saath.
class MousifyConnection extends ChangeNotifier {
  ConnState _state = ConnState.disconnected;
  ConnState get state => _state;
  bool get isReady => _state == ConnState.connected;

  String? host;
  int port = 9898;
  String? hostName; // PC ka naam — server batata hai
  String? osName; // PC ka OS — server batata hai (Windows/Fedora/Ubuntu)
  String? lastError;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _wantConnected = false;
  String? _token;

  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Server ke non-connection events (apps, etc.) — pages listen kar sakti hain.
  Stream<Map<String, dynamic>> get events => _events.stream;

  /// Test-only: server event inject karo (jaise 'shot') — bina real
  /// server ke flow test karne ke liye.
  @visibleForTesting
  void injectEvent(Map<String, dynamic> msg) {
    if (!_events.isClosed) _events.add(msg);
  }

  void connect(String newHost, int newPort, {String? token}) {
    host = newHost;
    port = newPort;
    _token = token;
    _wantConnected = true;
    lastError = null;
    _reconnectTimer?.cancel();
    _connectNow();
  }

  Future<void> _connectNow() async {
    await _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _setState(ConnState.connecting);
    try {
      final uri = Uri.parse('ws://$host:$port');
      final channel = IOWebSocketChannel.connect(
        uri,
        connectTimeout: const Duration(seconds: 4),
      );
      await channel.ready;
      _channel = channel;

      final hello = <String, dynamic>{'t': 'hello', 'name': 'mousify-app'};
      if (_token != null) hello['token'] = _token;
      channel.sink.add(jsonEncode(hello));

      _sub = channel.stream.listen(
        _onData,
        onDone: _onClosed,
        onError: (Object e) {
          lastError = e.toString();
          _onClosed();
        },
      );
    } catch (e) {
      lastError = "Can't reach $host:$port — check the IP and Wi-Fi";
      _setState(ConnState.connecting);
      _scheduleReconnect();
    }
  }

  void _onData(dynamic data) {
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(data as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    switch (msg['t']) {
      case 'hello-ok':
        hostName = msg['host'] as String?;
        osName = msg['os'] as String?;
        _setState(ConnState.connected);
        _startPing();
        break;
      case 'pair-required':
        // Pair-with-code hata diya — server code maange to QR scan
        // karo (Connect sheet ya Settings). waitingPair state nahi
        // rahi, is liye seedha disconnected + error.
        lastError = 'Pairing required — scan the QR code from the Connect sheet';
        _wantConnected = false;
        _setState(ConnState.disconnected);
        break;
      case 'error':
        if (kDebugMode) debugPrint('server error: ${msg['msg']}');
        lastError = msg['msg'] as String?;
        notifyListeners();
        break;
      default:
        if (!_events.isClosed) _events.add(msg);
        break;
    }
  }

  void _onClosed() {
    _stopPing();
    if (!_wantConnected) {
      _setState(ConnState.disconnected);
      return;
    }
    _setState(ConnState.connecting);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_wantConnected) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      if (_wantConnected) _connectNow();
    });
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => send(const {'t': 'ping'}),
    );
  }

  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void disconnect() {
    _wantConnected = false;
    _reconnectTimer?.cancel();
    _stopPing();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
    osName = null;
    _setState(ConnState.disconnected);
  }

  void send(Map<String, dynamic> msg) {
    final ch = _channel;
    if (ch != null && _state == ConnState.connected) {
      ch.sink.add(jsonEncode(msg));
    }
  }

  // --- protocol helpers ----------------------------------------------------
  void move(double dx, double dy) =>
      send({'t': 'move', 'dx': dx.round(), 'dy': dy.round()});

  /// PC check karta hai ke focused element typing field hai?
  /// Return: true/false (pata chala) ya null (unsupported/timeout).
  Future<bool?> checkTypingTarget({
    Duration timeout = const Duration(milliseconds: 1500),
  }) {
    if (!isReady) return Future.value(null);
    final completer = Completer<bool?>();
    late final StreamSubscription<Map<String, dynamic>> sub;
    sub = events.listen((msg) {
      if (msg['t'] == 'typing-target' && !completer.isCompleted) {
        completer.complete(
          msg['supported'] == true ? (msg['ok'] == true) : null,
        );
      }
    });
    send({'t': 'check-typing'});
    return completer.future
        .timeout(timeout, onTimeout: () => null)
        .whenComplete(() => sub.cancel());
  }

  void scroll(double dy) => send({'t': 'scroll', 'dy': dy.round()});

  void button(String b, String a) => send({'t': 'button', 'b': b, 'a': a});

  void keyTap(String k, {bool ctrl = false, bool shift = false, bool alt = false}) =>
      send({'t': 'key', 'k': k, 'ctrl': ctrl, 'shift': shift, 'alt': alt});

  void backspace(int count) =>
      send({'t': 'key', 'k': 'backspace', 'count': count});

  void _setState(ConnState s) {
    if (_state == s) return;
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _events.close();
    super.dispose();
  }
}
