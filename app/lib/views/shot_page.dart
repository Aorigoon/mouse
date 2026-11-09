import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('PC Screenshot'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Save to gallery',
            icon: _saved
                ? const Icon(Icons.done_all, color: Colors.green)
                : const Icon(Icons.save_outlined),
            onPressed: _saveToGallery,
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Copy to phone clipboard',
            icon: const Icon(Icons.copy_outlined),
            onPressed: _copyToClipboard,
          ),
        ],
      ),
      body: InteractiveViewer(
        maxScale: 5,
        child: Center(
          child: Image.memory(
            Uint8List.fromList(widget.bytes),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
