import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connection/server_connection.dart';
import '../theme.dart';

/// Terminal Peek — PC ke active terminal ka TEXT preview (AT-SPI se).
/// Pixel-streaming nahi hai — terminal ka content phone par dikh jata hai.
class TerminalPeekPage extends StatefulWidget {
  const TerminalPeekPage({super.key});

  @override
  State<TerminalPeekPage> createState() => _TerminalPeekPageState();
}

class _TerminalPeekPageState extends State<TerminalPeekPage> {
  String _text = '';
  bool _ok = false;
  String? _reason;
  bool _loading = true;
  Timer? _autoTimer;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _sub = context.read<MousifyConnection>().events.listen(_onEvent);
    _peek();
    _autoTimer = Timer.periodic(const Duration(seconds: 2), (_) => _peek());
  }

  StreamSubscription? _sub;

  void _onEvent(Map<String, dynamic> msg) {
    if (msg['t'] != 'terminal-text' || !mounted) return;
    setState(() {
      _ok = msg['ok'] == true;
      _text = (msg['text'] as String? ?? '');
      _reason = msg['reason'] as String?;
      _loading = false;
    });
    // neeche scroll (terminal ka latest output)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _peek() {
    final conn = context.read<MousifyConnection>();
    if (!conn.isReady) {
      setState(() {
        _loading = false;
        _ok = false;
        _reason = 'not-connected';
      });
      return;
    }
    conn.send({'t': 'terminal-peek'});
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _sub?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final monoStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 11.5,
      height: 1.45,
      color: Colors.white.withValues(alpha: 0.92),
    );
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _ok ? AppColors.live : Colors.transparent,
                border: Border.all(
                  color: _ok ? AppColors.live : scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Terminal Peek'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _peek,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : !_ok
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        _reason == 'not-connected'
                            ? 'Not connected — Settings me PC connect karo'
                            : 'No active terminal found on the PC.\n'
                                'Terminal kholo, phir refresh karo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(_text, style: monoStyle),
                  ),
      ),
    );
  }
}

