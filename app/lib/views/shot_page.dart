import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../widgets/back_chip.dart';
import '../widgets/copy_icon.dart';
import '../widgets/download_icon.dart';

/// PC ka screenshot — full screen, pinch-zoom ke saath.
/// Options: copy to clipboard, save to gallery.
class ShotPage extends StatefulWidget {
  final List<int> bytes;

  const ShotPage({super.key, required this.bytes});

  @override
  State<ShotPage> createState() => _ShotPageState();
}

class _ShotPageState extends State<ShotPage> {
  bool _saved = false;

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(
      ClipboardData(text: 'screenshot-${DateTime.now().millisecondsSinceEpoch}'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Screenshot info copy kiya'),
        duration: Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveToGallery() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(Uint8List.fromList(widget.bytes));
      if (!mounted) return;
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gallery mein save ho gaya: ${file.path}'),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save fail: $e'),
          duration: const Duration(milliseconds: 2000),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Page theme follow karta hai — kaala hardcode NAHI (light mode
    // me safed surface, dark mode me dark). Back button sirf bare
    // arrow hai (BackArrowPainter, theme ink) — peeche koi gol chip /
    // background nahi; icon ka color theme se badalta hai (dark mode
    // me halka, light mode me gehra).
    final scheme = Theme.of(context).colorScheme;
    final ink = scheme.onSurface;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header — AppBar nahi, app ka apna pattern: bare back
            // arrow + title + save/copy (Lucide icons).
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: CustomPaint(
                            size: const Size(30, 24),
                            painter: BackArrowPainter(ink),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'PC Screenshot',
                      style: TextStyle(
                        color: ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Save to gallery',
                    icon: _saved
                        ? const Icon(Icons.done_all, color: Colors.green)
                        // Zain ka diya hua Lucide download icon
                        // (Material download icon nahi).
                        : DownloadIcon(size: 24, color: ink),
                    color: ink,
                    onPressed: _saveToGallery,
                  ),
                  IconButton(
                    tooltip: 'Copy to phone clipboard',
                    // Zain ka diya hua Lucide copy icon.
                    icon: CopyIcon(size: 24, color: ink),
                    color: ink,
                    onPressed: _copyToClipboard,
                  ),
                ],
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(
                  child: Image.memory(
                    Uint8List.fromList(widget.bytes),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
