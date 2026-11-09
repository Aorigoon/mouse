import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connection/server_connection.dart';
import 'shot_page.dart';

/// Tools — khoobsurat card-based design. Media transport, volume,
/// editing keys, screenshot (save to gallery), windows switcher.
class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  late final MousifyConnection _conn;
  StreamSubscription? _sub;
  double? _volume;
  List<Map<String, String>> _windows = [];
  bool _windowsLoading = false;

  @override
  void initState() {
    super.initState();
    _conn = context.read<MousifyConnection>();
    _sub = _conn.events.listen(_onEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) => _request());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onEvent(Map<String, dynamic> msg) {
    if (!mounted) return;
    switch (msg['t']) {
      case 'volume':
        final v = msg['value'];
        if (v is int) setState(() => _volume = v.toDouble());
        break;
      case 'shot':
        final data = msg['data'] as String?;
        if (data != null && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ShotPage(bytes: base64Decode(data)),
            ),
          );
        }
        break;
      case 'shot-fail':
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Screenshot fail: ${msg['reason']}')),
          );
        }
        break;
      case 'windows':
        final list = (msg['windows'] as List? ?? [])
            .map((w) => {
                  'app': w['app'] as String? ?? '',
                  'title': w['title'] as String? ?? '',
                })
            .toList();
        if (mounted) {
          setState(() {
            _windows = List<Map<String, String>>.from(list);
            _windowsLoading = false;
          });
        }
        break;
      default:
        break;
    }
  }

  void _request() {
    if (!_conn.isReady) return;
    _conn.send({'t': 'volume-get'});
    _conn.send({'t': 'windows-list'});
  }

  void _media(String action) {
    HapticFeedback.mediumImpact();
    _conn.send({'t': 'media', 'action': action});
  }

  void _setVolume(double v) {
    v = v.clamp(0, 100);
    setState(() => _volume = v);
    _conn.send({'t': 'volume', 'value': v.round()});
  }

  void _screenshot() {
    if (!_conn.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect to your PC in Settings first')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PC par "Capture" dialog confirm karo…'),
        duration: Duration(seconds: 3),
      ),
    );
    _conn.send({'t': 'screenshot'});
  }

  void _editKey(String k, {bool ctrl = false}) {
    HapticFeedback.selectionClick();
    _conn.send({'t': 'key', 'k': k, 'ctrl': ctrl});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final conn = context.watch<MousifyConnection>();
    final vol = _volume ?? 0;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Tools'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'PC screenshot',
            icon: const Icon(Icons.photo_camera_outlined),
            onPressed: _screenshot,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // ================= MEDIA — gaming transport =================
          _SectionLabel('MEDIA'),
          _Card(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MediaBtn(
                      icon: Icons.skip_previous_rounded,
                      label: 'Prev',
                      onTap: () => _media('prev'),
                    ),
                    _MediaBtn(
                      icon: Icons.replay_10_outlined,
                      label: '-10s',
                      onTap: () => _media('rewind10'),
                    ),
                    _MediaBtn(
                      icon: Icons.play_circle_outline,
                      label: 'Play/Pause',
                      filled: true,
                      onTap: () => _media('playpause'),
                      size: 86,
                    ),
                    _MediaBtn(
                      icon: Icons.forward_10_outlined,
                      label: '+10s',
                      onTap: () => _media('forward10'),
                    ),
                    _MediaBtn(
                      icon: Icons.skip_next_rounded,
                      label: 'Next',
                      onTap: () => _media('next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ================= VOLUME =================
          _SectionLabel('VOLUME'),
          _Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              child: Row(
                children: [
                  _MediaBtn(
                    icon: Icons.remove_rounded,
                    label: '−',
                    size: 52,
                    onTap: () => _setVolume(vol - 5),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${vol.round()}',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PC VOLUME',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _MediaBtn(
                    icon: Icons.add_rounded,
                    label: '+',
                    size: 52,
                    onTap: () => _setVolume(vol + 5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ================= EDITING =================
          _SectionLabel('EDITING (focused window)'),
          _Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _EditPill(
                    label: 'SELECT ALL',
                    onTap: () => _editKey('a', ctrl: true),
                  ),
                  _EditPill(
                    label: 'COPY',
                    onTap: () => _editKey('c', ctrl: true),
                  ),
                  _EditPill(
                    label: 'CUT',
                    onTap: () => _editKey('x', ctrl: true),
                  ),
                  _EditPill(
                    label: 'PASTE',
                    onTap: () => _editKey('v', ctrl: true),
                  ),
                  _EditPill(
                    label: 'DELETE',
                    onTap: () => _editKey('backspace'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ================= SCREENSHOT =================
          _BigAction(
            icon: Icons.photo_camera_outlined,
            label: 'SCREENSHOT',
            onTap: _screenshot,
            subtitle: 'PC ka screenshot lein aur gallery mein save karein',
          ),
          const SizedBox(height: 16),

          // ================= WINDOWS =================
          _SectionLabel('WINDOWS — TAP TO SWITCH'),
          _Card(
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _windows.isEmpty
                            ? (conn.isReady
                                ? 'Refresh dabao — khuli windows yahan'
                                : 'Not connected')
                            : 'PC par ${_windows.length} windows khuli hain',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    _windowsLoading
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            tooltip: 'Refresh',
                            icon: const Icon(Icons.refresh, size: 20),
                            onPressed: () => _conn.send({'t': 'windows-list'}),
                          ),
                  ],
                ),
                if (_windows.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (final w in _windows)
                    _WindowRow(
                      app: w['app']!,
                      title: w['title']!,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _conn.send({
                          't': 'focus-window',
                          'app': w['app'],
                          'title': w['title'],
                        });
                      },
                    ),
                ] else if (conn.isReady) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Koi window nahi mili',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 2.5,
          fontWeight: FontWeight.w800,
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
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }
}

/// Gaming media button — round, scale on press.
class _MediaBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final double size;
  final VoidCallback onTap;

  const _MediaBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
    this.size = 62,
  });

  @override
  State<_MediaBtn> createState() => _MediaBtnState();
}

class _MediaBtnState extends State<_MediaBtn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.filled ? scheme.primary : scheme.surface,
                border: Border.all(
                  color: widget.filled ? scheme.primary : scheme.outline,
                  width: widget.filled ? 2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha:
                          scheme.brightness == Brightness.dark ? 0.5 : 0.12,
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                size: widget.size * 0.45,
                color: widget.filled ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: widget.filled ? scheme.onPrimary : scheme.onSurfaceVariant,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Editing pill button.
class _EditPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _EditPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: scheme.surface,
          border: Border.all(color: scheme.outline, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Big full-width action button.
class _BigAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _BigAction({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: scheme.primary,
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: scheme.onPrimary),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: scheme.onPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onPrimary.withValues(alpha: 0.85),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Windows switcher row.
class _WindowRow extends StatelessWidget {
  final String app;
  final String title;
  final VoidCallback onTap;

  const _WindowRow({
    required this.app,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: const Icon(Icons.window_outlined, size: 18),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: Text(
        app,
        style: TextStyle(
          fontSize: 10.5,
          color: scheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}
