import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connection/discovery.dart';
import '../connection/server_connection.dart';
import '../connection/settings_store.dart';
import 'qr_scan_page.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final MousifyDiscovery _discovery = MousifyDiscovery();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '9898');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppSettings>().loaded.then((_) {
        if (!mounted) return;
        final s = context.read<AppSettings>();
        _hostController.text = s.host ?? '';
        _portController.text = s.port.toString();
      });
    });
  }

  @override
  void dispose() {
    _discovery.stop();
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _useServer(DiscoveredServer s) {
    final settings = context.read<AppSettings>();
    HapticFeedback.selectionClick();
    settings.setHost(s.address, s.port);
    _hostController.text = s.address;
    _portController.text = s.port.toString();
    _connectWithFeedback(s.address, s.port, token: settings.token);
  }

  void _manualConnect() {
    final settings = context.read<AppSettings>();
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 9898;
    if (host.isEmpty || port < 1 || port > 65535) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid IP and port (e.g. 192.168.1.10 : 9898)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    HapticFeedback.selectionClick();
    settings.setHost(host, port);
    _connectWithFeedback(host, port, token: settings.token);
  }

  Future<void> _connectWithFeedback(
    String host,
    int port, {
    String? token,
    String? pairCode,
  }) async {
    final conn = context.read<MousifyConnection>();
    conn.connect(host, port, token: token, pairCode: pairCode);

    var ok = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ConnectingDialog(
        host: host,
        port: port,
        onDone: (v) {
          ok = v;
          Navigator.of(ctx).pop();
        },
      ),
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${conn.hostName ?? host}:$port'),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => _ErrorDialog(
        host: host,
        port: port,
      ),
    );
  }

  Future<void> _scanQr() async {
    final settings = context.read<AppSettings>();
    HapticFeedback.selectionClick();
    final info = await Navigator.of(context).push<QrConnectInfo>(
      MaterialPageRoute<QrConnectInfo>(builder: (_) => const QrScanPage()),
    );
    if (info == null || !mounted) return;
    settings.setHost(info.host, info.port);
    if (info.token != null) settings.setToken(info.token!);
    _hostController.text = info.host;
    _portController.text = info.port.toString();
    await _connectWithFeedback(info.host, info.port, token: settings.token);
  }

  Future<void> _pairDialog() async {
    final settings = context.read<AppSettings>();
    final host = settings.host;
    if (host == null || host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a server or enter the IP first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final codeController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => _PairDialog(
        codeController: codeController,
        onPair: (code) {
          Navigator.of(ctx).pop();
          _connectWithFeedback(host, settings.port, pairCode: code);
        },
      ),
    );
    codeController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final conn = context.watch<MousifyConnection>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            expandedHeight: 110,
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary.withValues(alpha: 0.15),
                      scheme.primary.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ================= CONNECTION =================
                _SectionTitle(context, 'CONNECTION'),
                _Card(
                  child: Column(
                    children: [
                      _ConnectionHeader(
                        state: conn.state,
                        hostName: conn.hostName,
                        host: conn.host,
                        port: conn.port,
                        lastError: conn.lastError,
                        onDisconnect: conn.state == ConnState.connected
                            ? conn.disconnect
                            : null,
                        onConnect: conn.state != ConnState.connected
                            ? _manualConnect
                            : null,
                      ),
                      const Divider(height: 1),
                      _SettingsRow(
                        icon: Icons.qr_code_scanner,
                        title: 'Connect via QR code',
                        subtitle: 'PC screen par QR scan karke jaldi connect karein',
                        onTap: _scanQr,
                      ),
                      _SettingsRow(
                        icon: Icons.key_outlined,
                        title: 'Pair with 6-digit code',
                        subtitle: 'PC app se pairing code lein aur yahan enter karein',
                        onTap: _pairDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ================= NEARBY =================
                _SectionTitle(context, 'NEARBY SERVERS'),
                _Card(
                  child: Column(
                    children: [
                      ListTile(
                        dense: true,
                        title: Text(
                          _discovery.scanning ? 'Searching…' : 'Scan karo',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: _discovery.scanning
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                tooltip: 'Scan again',
                                icon: const Icon(Icons.refresh),
                                onPressed: _discovery.start,
                              ),
                      ),
                      if (_discovery.servers.isNotEmpty)
                        ..._discovery.servers.map((s) => _ServerTile(
                              server: s,
                              isActive:
                                  settings.host == s.address &&
                                      settings.port == s.port,
                              onTap: () => _useServer(s),
                            ))
                      else
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Koi nearby server nahi mila',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ================= MANUAL =================
                _SectionTitle(context, 'MANUAL IP & PORT'),
                _Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _hostController,
                                decoration: const InputDecoration(
                                  labelText: 'PC IP address',
                                  hintText: '192.168.1.10',
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 92,
                              child: TextField(
                                controller: _portController,
                                decoration: const InputDecoration(
                                  labelText: 'Port',
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _manualConnect,
                            icon: const Icon(Icons.lan_outlined, size: 18),
                            label: const Text('Connect'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ================= INPUT =================
                _SectionTitle(context, 'INPUT SETTINGS'),
                _Card(
                  child: Column(
                    children: [
                      _SliderTile(
                        context,
                        label: 'Pointer sensitivity',
                        valueText: settings.sensitivity.toStringAsFixed(1),
                        onMinus: () => settings.setSensitivity(
                            (settings.sensitivity - 0.1).clamp(0.5, 3.0)),
                        onPlus: () => settings.setSensitivity(
                            (settings.sensitivity + 0.1).clamp(0.5, 3.0)),
                      ),
                      _SliderTile(
                        context,
                        label: 'Scroll speed',
                        valueText: settings.scrollSpeed.toStringAsFixed(1),
                        onMinus: () => settings.setScrollSpeed(
                            (settings.scrollSpeed - 0.1).clamp(0.5, 3.0)),
                        onPlus: () => settings.setScrollSpeed(
                            (settings.scrollSpeed + 0.1).clamp(0.5, 3.0)),
                      ),
                      _SliderTile(
                        context,
                        label: 'Wheel sensitivity',
                        valueText: settings.wheelSensitivity.toStringAsFixed(1),
                        onMinus: () => settings.setWheelSensitivity(
                            (settings.wheelSensitivity - 0.1).clamp(0.5, 3.0)),
                        onPlus: () => settings.setWheelSensitivity(
                            (settings.wheelSensitivity + 0.1).clamp(0.5, 3.0)),
                      ),
                      SwitchListTile(
                        title: const Text('Natural scrolling'),
                        subtitle: const Text(
                          'Scroll direction ulat kar dein',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: settings.naturalScroll,
                        onChanged: settings.setNaturalScroll,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      _SliderTile(
                        context,
                        label: 'Double-tap speed',
                        valueText: '${settings.doubleTapSpeed.round()} ms',
                        onMinus: () => settings.setDoubleTapSpeed(
                            (settings.doubleTapSpeed - 25).clamp(200, 500)),
                        onPlus: () => settings.setDoubleTapSpeed(
                            (settings.doubleTapSpeed + 25).clamp(200, 500)),
                      ),
                      const ListTile(
                        dense: true,
                        leading: Icon(Icons.bolt_rounded, size: 20),
                        title: Text('Double-tap the touchpad'),
                        subtitle: Text(
                          'Opens the live composer on a typing spot',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ================= APPEARANCE =================
                _SectionTitle(context, 'APPEARANCE'),
                _Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Theme',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: true,
                              icon: Icon(Icons.dark_mode, size: 20),
                              label: Text('Dark'),
                            ),
                            ButtonSegment(
                              value: false,
                              icon: Icon(Icons.light_mode, size: 20),
                              label: Text('Light'),
                            ),
                          ],
                          selected: {settings.isDark},
                          onSelectionChanged: (sel) => settings.setDark(sel.first),
                          showSelectedIcon: false,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final BuildContext context;
  final String title;

  const _SectionTitle(this.context, this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _ConnectionHeader extends StatelessWidget {
  final ConnState state;
  final String? hostName;
  final String? host;
  final int port;
  final String? lastError;
  final VoidCallback? onDisconnect;
  final VoidCallback? onConnect;

  const _ConnectionHeader({
    required this.state,
    this.hostName,
    this.host,
    required this.port,
    this.lastError,
    this.onDisconnect,
    this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final connected = state == ConnState.connected;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected
                      ? 'Connected to ${hostName ?? 'PC'}'
                      : state == ConnState.connecting
                          ? 'Connecting…'
                          : state == ConnState.waitingPair
                              ? 'Pairing required'
                              : 'Offline',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  connected
                      ? '${host ?? 'no IP'}:$port'
                      : lastError ??
                          '${host ?? 'No PC set yet'}:$port',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          connected
              ? IconButton(
                  tooltip: 'Disconnect',
                  icon: const Icon(Icons.stop_circle_outlined, size: 28),
                  color: Colors.red,
                  onPressed: onDisconnect,
                )
              : FilledButton(
                  onPressed: onConnect,
                  child: const Text('Connect'),
                ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: Icon(icon, color: scheme.onSurface),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: scheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

class _ServerTile extends StatelessWidget {
  final DiscoveredServer server;
  final bool isActive;
  final VoidCallback onTap;

  const _ServerTile({
    required this.server,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: const Icon(Icons.computer_outlined),
      title: Text(server.name),
      subtitle: Text('${server.address}:${server.port}'),
      trailing: isActive
          ? Icon(Icons.check_circle, color: scheme.primary)
          : Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}

class _SliderTile extends StatelessWidget {
  final BuildContext context;
  final String label;
  final String valueText;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _SliderTile(
    this.context, {
    required this.label,
    required this.valueText,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          _StepBtn(context, Icons.remove_rounded, onMinus),
          Container(
            width: 76,
            alignment: Alignment.center,
            child: Text(
              valueText,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _StepBtn(context, Icons.add_rounded, onPlus),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final BuildContext context;
  final IconData icon;
  final VoidCallback onTap;

  const _StepBtn(this.context, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.surface,
          border: Border.all(color: scheme.outline),
        ),
        child: Icon(icon, size: 18, color: scheme.onSurface),
      ),
    );
  }
}

/// Pair dialog with 6-digit code input.
class _PairDialog extends StatelessWidget {
  final TextEditingController codeController;
  final ValueChanged<String> onPair;

  const _PairDialog({
    required this.codeController,
    required this.onPair,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text('Pair with 6-digit code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'On the PC open the Mousify app → "Show pairing code", '
            'then enter it here:',
            style: TextStyle(
              fontSize: 13.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: codeController,
            autofocus: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(hintText: '6-digit code'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final code = codeController.text.trim();
            if (code.length != 6) return;
            onPair(code);
          },
          child: const Text('Pair'),
        ),
      ],
    );
  }
}

/// Connecting spinner dialog.
class _ConnectingDialog extends StatefulWidget {
  final String host;
  final int port;
  final ValueChanged<bool> onDone;

  const _ConnectingDialog({
    required this.host,
    required this.port,
    required this.onDone,
  });

  @override
  State<_ConnectingDialog> createState() => _ConnectingDialogState();
}

class _ConnectingDialogState extends State<_ConnectingDialog> {
  @override
  void initState() {
    super.initState();
    final conn = context.read<MousifyConnection>();
    waitForConnection(conn).then((ok) {
      if (mounted) widget.onDone(ok);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 2.4),
          const SizedBox(height: 20),
          const Text(
            'Connecting to the server…',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.host}:${widget.port}',
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Error dialog when connection fails.
class _ErrorDialog extends StatelessWidget {
  final String host;
  final int port;

  const _ErrorDialog({
    required this.host,
    required this.port,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      icon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: scheme.primary,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.error_outline,
          size: 32,
          color: scheme.onSurface,
        ),
      ),
      title: const Text("Couldn't connect"),
      content: Text(
        "Couldn't reach $host:$port.\n\n"
        '• Are the phone and PC on the same Wi-Fi?\n'
        '• Is the server running? (Mousify app → status)\n'
        '• Is port $port allowed in the firewall?',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14.5, height: 1.5),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Try again'),
        ),
      ],
    );
  }
}
