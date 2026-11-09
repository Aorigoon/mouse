import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';

class DiscoveredServer {
  final String name;
  final String address;
  final int port;

  const DiscoveredServer({
    required this.name,
    required this.address,
    required this.port,
  });
}

/// LAN par `_mousify._tcp` services dhoondta hai (mDNS / NSD).
class MousifyDiscovery extends ChangeNotifier {
  final List<DiscoveredServer> servers = [];
  BonsoirDiscovery? _discovery;
  StreamSubscription? _sub;
  bool scanning = false;

  Future<void> start() async {
    await stop();
    scanning = true;
    notifyListeners();
    try {
      final d = BonsoirDiscovery(type: '_mousify._tcp');
      await d.initialize();
      _discovery = d;
      _sub = d.eventStream?.listen((event) {
        if (event is BonsoirDiscoveryServiceFoundEvent) {
          d.serviceResolver.resolveService(event.service);
        } else if (event is BonsoirDiscoveryServiceResolvedEvent) {
          final svc = event.service;
          final addr = svc.hostAddresses.isNotEmpty ? svc.hostAddresses.first : svc.hostname;
          if (addr == null || addr.isEmpty) return;
          final found = DiscoveredServer(
            name: svc.name,
            address: addr,
            port: svc.port,
          );
          servers
            ..removeWhere((s) => s.address == found.address && s.port == found.port)
            ..insert(0, found);
          notifyListeners();
        } else if (event is BonsoirDiscoveryServiceLostEvent) {
          servers.removeWhere((s) => s.name == event.service.name);
          notifyListeners();
        }
      });
      await d.start();
    } catch (e) {
      if (kDebugMode) debugPrint('discovery fail: $e');
      scanning = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    scanning = false;
    await _sub?.cancel();
    _sub = null;
    final d = _discovery;
    _discovery = null;
    try {
      await d?.stop();
    } catch (_) {}
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
