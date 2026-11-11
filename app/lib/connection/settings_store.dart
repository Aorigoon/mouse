import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saari app settings — SharedPreferences me persist hoti hain.
class AppSettings extends ChangeNotifier {
  final Completer<void> _loadedCompleter = Completer<void>();
  Future<void> get loaded => _loadedCompleter.future;

  late SharedPreferences _prefs;

  String? host;
  int port = 9898;
  String? token;
  String deviceName = 'android';
  double sensitivity = 1.4;
  double scrollSpeed = 1.0;
  double wheelSensitivity = 1.0;
  double doubleTapSpeed = 350; // ms window
  bool naturalScroll = false;
  bool swapButtons = false;
  // Theme — teen mode: light / dark / system (phone ki setting).
  ThemeMode themeMode = ThemeMode.light; // light default
  // Haptic feedback — Settings → Haptic feedback toggle (default ON).
  // `hapticsEnabled` static mirror hai taaki `Haptics` helper bina
  // BuildContext ke bhi check kar sake (37 call sites).
  bool hapticFeedback = true;
  static bool hapticsEnabled = true;
  // Motion Control — phone tilt se cursor move (default off).
  bool motionControl = false;
  double motionSensitivity = 1.0;
  List<String> history = [];
  List<String> pinnedApps = [];
  String? appsCacheJson; // "id|name" entries — offline dock ke liye

  AppSettings() {
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    host = _prefs.getString('host');
    port = _prefs.getInt('port') ?? 9898;
    token = _prefs.getString('token');
    deviceName = _prefs.getString('device_name') ?? 'android';
    sensitivity = _prefs.getDouble('sensitivity') ?? 1.4;
    scrollSpeed = _prefs.getDouble('scroll_speed') ?? 1.0;
    wheelSensitivity = _prefs.getDouble('wheel_sensitivity') ?? 1.0;
    doubleTapSpeed = _prefs.getDouble('double_tap_speed') ?? 350;
    naturalScroll = _prefs.getBool('natural_scroll') ?? false;
    swapButtons = _prefs.getBool('swap_buttons') ?? false;
    motionControl = _prefs.getBool('motion_control') ?? false;
    motionSensitivity = _prefs.getDouble('motion_sensitivity') ?? 1.0;
    // Theme mode — purani `is_dark` bool se migrate (dark→dark,
    // light→light); default Light (jaisa pehle tha).
    final storedTheme = _prefs.getString('theme_mode');
    if (storedTheme != null) {
      themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == storedTheme,
        orElse: () => ThemeMode.light,
      );
    } else {
      themeMode =
          (_prefs.getBool('is_dark') ?? false) ? ThemeMode.dark : ThemeMode.light;
    }
    hapticFeedback = _prefs.getBool('haptic_feedback') ?? true;
    hapticsEnabled = hapticFeedback;
    history = _prefs.getStringList('history') ?? [];
    pinnedApps = _prefs.getStringList('pinned_apps') ?? [];
    appsCacheJson = _prefs.getString('apps_cache');
    _loadedCompleter.complete();
    notifyListeners();
  }

  void setHost(String? newHost, int newPort) {
    host = newHost;
    port = newPort;
    _prefs.setString('host', newHost ?? '');
    _prefs.setInt('port', newPort);
    notifyListeners();
  }

  void setToken(String newToken) {
    token = newToken;
    _prefs.setString('token', newToken);
    notifyListeners();
  }

  void setSensitivity(double v) {
    sensitivity = v;
    _prefs.setDouble('sensitivity', v);
    notifyListeners();
  }

  void setScrollSpeed(double v) {
    scrollSpeed = v;
    _prefs.setDouble('scroll_speed', v);
    notifyListeners();
  }

  void setWheelSensitivity(double v) {
    wheelSensitivity = v;
    _prefs.setDouble('wheel_sensitivity', v);
    notifyListeners();
  }

  void setDoubleTapSpeed(double v) {
    doubleTapSpeed = v;
    _prefs.setDouble('double_tap_speed', v);
    notifyListeners();
  }

  void setNaturalScroll(bool v) {
    naturalScroll = v;
    _prefs.setBool('natural_scroll', v);
    notifyListeners();
  }

  void setSwapButtons(bool v) {
    swapButtons = v;
    _prefs.setBool('swap_buttons', v);
    notifyListeners();
  }

  void setMotionControl(bool v) {
    motionControl = v;
    _prefs.setBool('motion_control', v);
    notifyListeners();
  }

  void setMotionSensitivity(double v) {
    motionSensitivity = v;
    _prefs.setDouble('motion_sensitivity', v);
    notifyListeners();
  }

  void togglePinnedApp(String appId) {
    if (pinnedApps.contains(appId)) {
      pinnedApps.remove(appId);
    } else {
      pinnedApps.insert(0, appId);
    }
    _prefs.setStringList('pinned_apps', pinnedApps);
    notifyListeners();
  }

  bool isPinned(String appId) => pinnedApps.contains(appId);

  void setAppsCache(String json) {
    appsCacheJson = json;
    _prefs.setString('apps_cache', json);
  }

  void setThemeMode(ThemeMode m) {
    themeMode = m;
    _prefs.setString('theme_mode', m.name);
    notifyListeners();
  }

  void setHapticFeedback(bool v) {
    hapticFeedback = v;
    hapticsEnabled = v;
    _prefs.setBool('haptic_feedback', v);
    notifyListeners();
  }

  void addHistory(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    history
      ..removeWhere((h) => h == t)
      ..insert(0, t);
    if (history.length > 15) history.removeRange(15, history.length);
    _prefs.setStringList('history', history);
    notifyListeners();
  }

  void removeHistory(String text) {
    history.remove(text);
    _prefs.setStringList('history', history);
    notifyListeners();
  }
}
