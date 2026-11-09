import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connection/live_typing.dart';
import '../connection/server_connection.dart';

/// Composer — ek seedha notepad page: jo likho/dictate karo wo real-time
/// PC ke focused window me type hota hai (add + delete dono). Bas.
class ComposerPage extends StatefulWidget {
  const ComposerPage({super.key});

  @override
  State<ComposerPage> createState() => _ComposerPageState();
}

class _ComposerPageState extends State<ComposerPage> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String _lastSent = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    final conn = context.read<MousifyConnection>();
    if (!conn.isReady) return;
    final delta = computeTextDelta(_lastSent, _controller.text);
    _lastSent = _controller.text;
    if (delta.deleteCount == 0 && delta.insert.isEmpty) return;
    if (delta.deleteCount > 0) conn.backspace(delta.deleteCount);
    if (delta.insert.isEmpty) return;
    conn.send({'t': 'text', 's': delta.insert});
  }

  void _clear() {
    final conn = context.read<MousifyConnection>();
    final text = _controller.text;
    if (text.isNotEmpty) {
      conn.backspace(text.length);
    }
    _controller.clear();
  }

  /// Poora text phone ke clipboard mein copy kare.
  Future<void> _copyAll() async {
    final text = _controller.text;
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Re-type: poora text dobara PC par bhejta hai (desktop focus ke liye).
  void _reType() {
    final conn = context.read<MousifyConnection>();
    if (!conn.isReady) return;
    final text = _controller.text;
    if (text.isEmpty) return;
    // Sab kuch delete karke dobara type karein
    conn.backspace(text.length);
    conn.send({'t': 'text', 's': text});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasText = _controller.text.isNotEmpty;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _CloseButton(
          onTap: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Composer',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
        centerTitle: true,
        actions: [
          if (hasText) ...[
            // Clear button
            _HeaderActionBtn(
              icon: Icons.delete_outline,
              tooltip: 'Clear',
              onTap: _clear,
              color: scheme.error,
            ),
            const SizedBox(width: 6),
            // Copy button
            _HeaderActionBtn(
              icon: Icons.content_copy_outlined,
              tooltip: 'Copy',
              onTap: _copyAll,
              color: scheme.primary,
            ),
            const SizedBox(width: 6),
            // Re-type button
            _HeaderActionBtn(
              icon: Icons.replay_outlined,
              tooltip: 'Re-type',
              onTap: _reType,
              color: scheme.secondary,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.outline.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 17,
            height: 1.7,
            fontFamily: 'monospace',
          ),
          decoration: InputDecoration(
            hintText: 'Start writing…',
            hintStyle: TextStyle(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
              fontSize: 17,
              height: 1.7,
            ),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

/// Close button — black rounded background, white icon.
class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.close,
          size: 20,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Header action button — icon only, compact for AppBar.
class _HeaderActionBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  const _HeaderActionBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color, width: 1.2),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}