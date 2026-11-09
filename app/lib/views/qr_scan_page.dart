import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Parse result — `mousify://connect?host=..&port=..&token=..`
class QrConnectInfo {
  final String host;
  final int port;
  final String? token;

  const QrConnectInfo({required this.host, required this.port, this.token});

  static QrConnectInfo? tryParse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != 'mousify' || uri.host != 'connect') {
      return null;
    }
    final host = uri.queryParameters['host'];
    if (host == null || host.isEmpty) return null;
    final port = int.tryParse(uri.queryParameters['port'] ?? '') ?? 9898;
    return QrConnectInfo(
      host: host,
      port: port,
      token: uri.queryParameters['token'],
    );
  }
}

/// Camera kholkar PC ka QR scan karta hai — detect hote hi result ke saath wapas.
class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.qrCode],
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue ?? barcode.displayValue;
      if (raw == null) continue;
      final info = QrConnectInfo.tryParse(raw);
      if (info == null) continue;
      _handled = true;
      if (mounted) Navigator.of(context).pop(info);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "Couldn't open the camera.\n$error",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            ),
          ),
          // scan frame overlay
          Center(
            child: IgnorePointer(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.primary, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: Text(
              'Point the camera at the QR shown on the PC',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
