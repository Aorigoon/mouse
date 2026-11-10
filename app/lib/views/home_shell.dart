import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connection/server_connection.dart';
import '../connection/settings_store.dart';
import '../utils/motion_control.dart';
import '../utils/shake.dart';
import '../utils/shake_service.dart';
import '../widgets/floating_nav_bar.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dock_page.dart';
import 'tools_page.dart';
import 'home_page.dart';
import 'settings_view.dart';
import 'composer_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _pageController = PageController();
  ShakeDetector? _shake;
  MotionController? _motion;
  AppSettings? _settings;
  int _shakeCount = 0;
  Timer? _shakeResetTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _wireUp();
      _initForegroundService();
    });
    // Shake → 1-2 shake: mouse page, 3-4 shake: composer page
    try {
      _shake = ShakeDetector(onShake: _onShake)..start();
    } catch (_) {
      // web/desktop par accelerometer na ho to ignore
    }
  }

  @override
  void dispose() {
    _shake?.stop();
    _settings?.removeListener(_syncMotion);
    _motion?.dispose();
    _pageController.dispose();
    _shakeResetTimer?.cancel();
    super.dispose();
  }

  /// Motion Control toggle badle to controller sync karo.
  void _syncMotion() => _motion?.sync();

  void _onShake() {
    setState(() {
      _shakeCount++;
    });
    _shakeResetTimer?.cancel();
    _shakeResetTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        if (_shakeCount >= 1 && _shakeCount <= 2) {
          _goToMouse();
        } else if (_shakeCount >= 3 && _shakeCount <= 4) {
          _openComposer();
        }
        _shakeCount = 0;
      });
    });
  }

  void _openComposer() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ComposerPage()),
    );
  }

  void _wireUp() {
    final settings = context.read<AppSettings>();
    final conn = context.read<MousifyConnection>();
    conn.onTokenPaired = settings.setToken;
    // Motion Control — sheet ka toggle badle to turant on/off.
    _settings = settings;
    _motion = MotionController(conn: conn, settings: settings);
    settings.addListener(_syncMotion);
    _motion!.sync();
    settings.loaded.then((_) {
      if (!mounted) return;
      final host = settings.host;
      if (host != null && host.isNotEmpty) {
        conn.connect(host, settings.port, token: settings.token);
      }
    });
  }

  /// Shake-to-open service — app band ho (swipe away) tab bhi shake
  /// pakadta hai aur app wapas khol deta hai.
  Future<void> _initForegroundService() async {
    try {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'mousify_shake',
          channelName: 'Mousify shake service',
          channelDescription: 'Shake the phone to open Mousify',
          onlyAlertOnce: true,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.nothing(),
          autoRunOnBoot: true,
          allowWakeLock: true,
        ),
      );
      await FlutterForegroundTask.requestNotificationPermission();
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
      if (!await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.startService(
          serviceId: 256,
          notificationTitle: 'Mousify',
          notificationText: 'Shake the phone to open the touchpad',
          callback: mousifyServiceCallback,
        );
      }
    } catch (_) {
      // service fail ho to app normal chalti rahe
    }
  }

  void _goToMouse() {
    if (!mounted) return;
    // Settings ke field par focus ho to keyboard band karo.
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).popUntil((r) => r.isFirst);
    setState(() => _index = 0);
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Android back: Apps/Settings/Composer se → Home; Home par → app exit
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) {
          setState(() => _index = 0);
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      },
      child: Scaffold(
        // Floating nav ke peeche content dikhe — nav screen se upar tairta hai.
        extendBody: true,
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              // Home (mouse) par swipe disabled — warna cursor moves page palat dete
              physics: _index == 0
                  ? const NeverScrollableScrollPhysics()
                  : const ClampingScrollPhysics(),
              onPageChanged: (i) {
                HapticFeedback.selectionClick();
                // Tab badla — pichle tab ka field (Settings IP/port)
                // focus na rakhe, warna keyboard touchpad par khula rehta hai.
                FocusManager.instance.primaryFocus?.unfocus();
                setState(() => _index = i);
              },
              children: const [
                _KeepAlive(child: HomePage()),
                _KeepAlive(child: DockPage()),
                _KeepAlive(child: ToolsPage()),
                _KeepAlive(child: SettingsView()),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingNavBar(
                currentIndex: _index,
                onTap: _goTo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goTo(int i) {
    HapticFeedback.selectionClick();
    // Tab badla — pichle tab ka field (Settings IP/port) focus na
    // rakhe, warna keyboard touchpad par khula rehta hai.
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _index = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }
}

/// PageView off-screen pages ka state preserve rakhta hai.
class _KeepAlive extends StatefulWidget {
  final Widget child;

  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
