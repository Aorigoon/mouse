import 'package:flutter/material.dart';
import '../utils/haptics.dart';
import 'package:provider/provider.dart';

import '../connection/server_connection.dart';
import '../connection/settings_store.dart';
import '../theme.dart';
import '../views/qr_scan_page.dart';

/// Wifi icon se khulne wali Connect sheet — three-dot wali Settings
/// sheet jaisi hi style (dark #1C1C1E, drag handle, header, gray
/// #262628 card, flat matte, koi border/shadow nahi).
///
/// Sab se pehle scanner hai (PC ka QR scan karo), phir manual
/// IP/port type karke bhi connect kar sakte ho. Koi X close button
/// nahi — sheet neeche swipe karke, bahar tap karke, ya Connect /
/// Disconnect dabakar band hoti hai.
///
/// Andar: connection status (Connected/Offline + PC ka OS), PC IP
/// aur Port fields (saved values se prefilled), aur ek bada
/// Connect / Disconnect button. Pair-with-code hata diya hai —
/// pairing ab sirf QR scan se hoti hai (QR me token hota hai).
Future<void> showConnectSheet(BuildContext context) {
  Haptics.click();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ConnectSheet(),
  );
}

class _ConnectSheet extends StatefulWidget {
  const _ConnectSheet();

  @override
  State<_ConnectSheet> createState() => _ConnectSheetState();
}

class _ConnectSheetState extends State<_ConnectSheet> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppSettings>();
    _hostController = TextEditingController(text: settings.host ?? '');
    _portController =
        TextEditingController(text: settings.port.toString());
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _connect() {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 9898;
    if (host.isEmpty || port < 1 || port > 65535) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid IP and port (e.g. 192.168.1.10 : 9898)',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _connectWith(host, port);
  }

  /// Values save karke connection shuru karo, sheet band karo.
  void _connectWith(String host, int port) {
    final settings = context.read<AppSettings>();
    final conn = context.read<MousifyConnection>();
    // Snackbar sheet band hone ke baad bhi dikhe — messenger pehle
    // pakdo (pop ke baad context deactivate ho jata hai).
    final messenger = ScaffoldMessenger.of(context);
    Haptics.click();
    settings.setHost(host, port);
    conn.connect(host, port, token: settings.token);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Connecting to $host:$port…'),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// QR scanner — PC ka QR scan karo: IP/port/token QR se aate hain,
  /// fields bhar jate hain aur turant connect ho jata hai.
  Future<void> _scanQr() async {
    final settings = context.read<AppSettings>();
    final info = await Navigator.of(context).push<QrConnectInfo>(
      MaterialPageRoute<QrConnectInfo>(
        builder: (_) => const QrScanPage(),
      ),
    );
    if (info == null || !mounted) return;
    if (info.token != null) settings.setToken(info.token!);
    _hostController.text = info.host;
    _portController.text = info.port.toString();
    _connectWith(info.host, info.port);
  }

  void _disconnect() {
    Haptics.click();
    context.read<MousifyConnection>().disconnect();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<MousifyConnection>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final ink = scheme.onSurface;
    final connected = conn.state == ConnState.connected;
    final connecting = conn.state == ConnState.connecting;

    // Dark gray / light raised — flat matte, koi border line nahi.
    return Material(
      color: AppColors.chip(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        // Keyboard khule to sheet ke fields uske upar rahen.
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          // Chhoti screens par sheet scroll ho — overflow error nahi.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ink.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Header: sirf title, beech me — koi X close nahi.
                // Sheet neeche swipe karke ya bahar tap karke band
                // hoti hai (Connect/Disconnect par khud band hoti hai).
                Text(
                  'Connect to PC',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 14),
                // Scanner — sab se pehle: PC ka QR scan karo.
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.raised(isDark),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _scanQr,
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 14, 12, 14),
                        child: Row(
                          children: [
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 26,
                              color: ink.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Scan QR code',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'PC par QR dikhao, camera se scan karo',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          ink.withValues(alpha: 0.55),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 24,
                              color: ink.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Status + fields card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.raised(isDark),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status row
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: connected
                                    ? const Color(0xFF34C759)
                                    : connecting
                                        ? const Color(0xFFFFCC00)
                                        : ink.withValues(alpha: 0.35),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                connected
                                    ? 'Connected to ${conn.hostName ?? conn.host ?? ''}'
                                    : connecting
                                        ? 'Connecting…'
                                        : 'Not connected',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: ink,
                                ),
                              ),
                            ),
                            if (connected && conn.osName != null)
                              Text(
                                conn.osName!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: ink.withValues(alpha: 0.5),
                                ),
                              ),
                          ],
                        ),
                      ),
                      _FieldDivider(),
                      // PC IP field
                      _SheetTextField(
                        label: 'PC IP address',
                        hint: 'e.g. 192.168.1.10',
                        controller: _hostController,
                        keyboardType: TextInputType.text,
                      ),
                      _FieldDivider(),
                      // Port field
                      _SheetTextField(
                        label: 'Port',
                        hint: 'e.g. 9898',
                        controller: _portController,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Connect / Disconnect button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    // Connecting ke doran button disabled — dobara
                    // dabao to doosri connect shuru na ho.
                    onPressed: connected
                        ? _disconnect
                        : connecting
                            ? null
                            : _connect,
                    style: FilledButton.styleFrom(
                      backgroundColor: connected
                          ? const Color(0xFFFF453A)
                          : AppColors.accent,
                      foregroundColor: connected
                          ? Colors.white
                          : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: Text(
                      connected
                          ? 'Disconnect'
                          : connecting
                              ? 'Connecting…'
                              : 'Connect',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Card ke rows ke beech halki divider.
class _FieldDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 16),
      color: Theme.of(context)
          .colorScheme
          .onSurface
          .withValues(alpha: 0.08),
    );
  }
}

/// Sheet ke andar ek field — upar chhota label, neeche TextField.
class _SheetTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _SheetTextField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 2),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 16,
              ),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
