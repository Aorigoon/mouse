import 'dart:async';

import 'package:flutter/foundation.dart';

import 'server_connection.dart';

/// PC ki khuli window — app naam + window title.
class PcWindow {
  final String app;
  final String title;

  const PcWindow({required this.app, required this.title});
}

/// Windows service — PC ki khuli windows ki shared list.
///
/// Tools page ka WINDOWS section aur home page ka focus button
/// (neeche-right, Windows jaisa icon) dono yahi use karte hain —
/// is liye list ek jagah hai, do jagah nahi. Server se 'windows'
/// event aate hi list update hoti hai; `refresh()` se nayi list
/// mangwai jati hai; `focus()` se kisi window par switch hota hai.
class WindowsService extends ChangeNotifier {
  final MousifyConnection _conn;
  StreamSubscription? _sub;

  List<PcWindow> _windows = [];
  bool _loading = false;

  WindowsService(this._conn) {
    _sub = _conn.events.listen(_onEvent);
  }

  List<PcWindow> get windows => List.unmodifiable(_windows);
  bool get loading => _loading;

  void _onEvent(Map<String, dynamic> msg) {
    if (msg['t'] != 'windows') return;
    final list = (msg['windows'] as List? ?? [])
        .map(
          (w) => PcWindow(
            app: w['app'] as String? ?? '',
            title: w['title'] as String? ?? '',
          ),
        )
        .toList();
    _windows = list;
    _loading = false;
    notifyListeners();
  }

  /// Server se khuli windows ki nayi list mango.
  void refresh() {
    if (!_conn.isReady) return;
    _loading = true;
    notifyListeners();
    _conn.send(const {'t': 'windows-list'});
  }

  /// Is window par focus karo (PC par switch).
  void focus(PcWindow w) {
    _conn.send({'t': 'focus-window', 'app': w.app, 'title': w.title});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
