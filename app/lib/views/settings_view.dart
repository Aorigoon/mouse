import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../auth/auth_service.dart';
import '../connection/discovery.dart';
import '../connection/server_connection.dart';
import '../connection/settings_store.dart';
import '../theme.dart';
import '../widgets/connect_sheet.dart';
import '../widgets/mouse_controls_sheet.dart';
import 'auth_page.dart';
import 'profile_page.dart';

/// Settings — Muse app ke Settings screenshot jaisa.
///
/// • Har row: bare outline icon + title (+ subtitle) + chevron.
/// • Koi inline input nahi — na stepper, na slider, na switch, na
///   text field, na segmented control. Har setting par tap karo to
///   uski khubsurat bottom sheet khulti hai, input wahin hota hai.
/// • Free plan / Upgrade card nahi hai — Mousify ki koi subscription
///   nahi hai, is liye wo card copy nahi kiya.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  void _openProfile(BuildContext context) {
    final auth = context.read<AuthService>();
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            auth.isSignedIn ? const ProfilePage() : const AuthPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final conn = context.watch<MousifyConnection>();
    final auth = context.watch<AuthService>();
    final scheme = Theme.of(context).colorScheme;
    final user = auth.currentUser;
    final connected = conn.state == ConnState.connected;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title — screenshot jaisa center me (tab hai, is liye
              // back button nahi).
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 8, 4, 20),
                child: Text(
                  'Settings',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // ================= PROFILE =================
              _GroupCard(
                radius: 28,
                child: InkWell(
                  onTap: () => _openProfile(context),
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: user != null
                                ? scheme.primary
                                : scheme.surface,
                            border: user == null
                                ? Border.all(color: scheme.outline, width: 1.4)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: user != null
                              ? Text(
                                  user.initials,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onPrimary,
                                  ),
                                )
                              : Icon(
                                  Icons.person_outline_rounded,
                                  size: 28,
                                  color: scheme.onSurfaceVariant,
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'Guest',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.email ?? 'Tap to sign in to Mousify',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: scheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 26,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ================= CONNECTION =================
              _GroupCard(
                child: Column(
                  children: [
                    _SettingsRow(
                      icon: Icons.wifi_outlined,
                      title: 'Connection',
                      subtitle: connected
                          ? 'Connected to ${conn.hostName ?? 'PC'}'
                          : conn.state == ConnState.connecting
                              ? 'Connecting…'
                              : 'Offline',
                      onTap: () => showConnectSheet(context),
                    ),
                    const _RowDivider(),
                    _SettingsRow(
                      icon: Icons.radar_outlined,
                      title: 'Nearby servers',
                      subtitle: 'See PCs on your Wi-Fi',
                      onTap: () => _openServersSheet(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ================= MOUSE =================
              _GroupCard(
                child: Column(
                  children: [
                    _SettingsRow(
                      icon: Icons.speed_outlined,
                      title: 'Pointer sensitivity',
                      subtitle: settings.sensitivity.toStringAsFixed(1),
                      onTap: () => _openSliderSheet(
                        context,
                        title: 'Pointer sensitivity',
                        min: 0.5,
                        max: 3.0,
                        getValue: (s) => s.sensitivity,
                        setValue: (s, v) => s.setSensitivity(v),
                      ),
                    ),
                    const _RowDivider(),
                    _SettingsRow(
                      icon: Icons.swap_vert_outlined,
                      title: 'Scroll speed',
                      subtitle: settings.scrollSpeed.toStringAsFixed(1),
                      onTap: () => _openSliderSheet(
                        context,
                        title: 'Scroll speed',
                        min: 0.5,
                        max: 3.0,
                        getValue: (s) => s.scrollSpeed,
                        setValue: (s, v) => s.setScrollSpeed(v),
                      ),
                    ),
                    const _RowDivider(),
                    _SettingsRow(
                      icon: Icons.mouse_outlined,
                      title: 'Wheel sensitivity',
                      subtitle: settings.wheelSensitivity.toStringAsFixed(1),
                      onTap: () => _openSliderSheet(
                        context,
                        title: 'Wheel sensitivity',
                        min: 0.5,
                        max: 3.0,
                        getValue: (s) => s.wheelSensitivity,
                        setValue: (s, v) => s.setWheelSensitivity(v),
                      ),
                    ),
                    const _RowDivider(),
                    _SettingsRow(
                      icon: Icons.bolt_outlined,
                      title: 'Double-tap speed',
                      subtitle: '${settings.doubleTapSpeed.round()} ms',
                      onTap: () => _openSliderSheet(
                        context,
                        title: 'Double-tap speed',
                        min: 200,
                        max: 500,
                        getValue: (s) => s.doubleTapSpeed,
                        setValue: (s, v) => s.setDoubleTapSpeed(v),
                        formatValue: (v) => '${v.round()} ms',
                      ),
                    ),
                    const _RowDivider(),
                    _SettingsRow(
                      icon: Icons.swap_vertical_circle_outlined,
                      title: 'Natural scrolling',
                      subtitle:
                          settings.naturalScroll ? 'On' : 'Off',
                      onTap: () => _openNaturalScrollSheet(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ================= APPEARANCE =================
              _GroupCard(
                child: _SettingsRow(
                  icon: Icons.dark_mode_outlined,
                  title: 'Appearance',
                  subtitle: settings.isDark ? 'Dark' : 'Light',
                  onTap: () => _openAppearanceSheet(context),
                ),
              ),
              const SizedBox(height: 16),

              // ================= ABOUT =================
              _GroupCard(
                child: _SettingsRow(
                  icon: Icons.info_outline_rounded,
                  title: 'About Mousify',
                  subtitle: 'Version 1.0.0',
                  onTap: () => _openAboutSheet(context),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bada gol card — inspiration wale settings jaisa, flat matte.
class _GroupCard extends StatelessWidget {
  final Widget child;
  final double radius;

  const _GroupCard({required this.child, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Rows ke beech wali divider — icon ke baad se shuru.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 58,
      color: Theme.of(context).colorScheme.outline,
    );
  }
}

/// Screenshot jaisi row: bare outline icon + title (+ subtitle) +
/// side me chevron. Koi tile, koi inline control nahi — tap par
/// uski bottom sheet khulti hai.
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 24, color: scheme.onSurface),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= BOTTOM SHEETS =================

/// Har setting ki khubsurat bottom sheet — connect/mouse sheet
/// jaisi style (drag handle, gol top, flat matte).
Future<void> _openSheet(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SettingsSheet(title: title, child: child),
  );
}

class _SettingsSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return Material(
      color: AppColors.chip(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slider wali sheet — bada value label + gradient slider
/// (snail–rabbit, mouse sheet wala).
void _openSliderSheet(
  BuildContext context, {
  required String title,
  required double min,
  required double max,
  required double Function(AppSettings) getValue,
  required void Function(AppSettings, double) setValue,
  String Function(double)? formatValue,
}) {
  _openSheet(
    context,
    title: title,
    child: _SliderSheetContent(
      title: title,
      min: min,
      max: max,
      getValue: getValue,
      setValue: setValue,
      formatValue: formatValue,
    ),
  );
}

class _SliderSheetContent extends StatelessWidget {
  final String title;
  final double min;
  final double max;
  final double Function(AppSettings) getValue;
  final void Function(AppSettings, double) setValue;
  final String Function(double)? formatValue;

  const _SliderSheetContent({
    required this.title,
    required this.min,
    required this.max,
    required this.getValue,
    required this.setValue,
    this.formatValue,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final value = getValue(settings);
    final label =
        (formatValue ?? (v) => v.toStringAsFixed(1))(value);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        SpeedSlider(
          min: min,
          max: max,
          value: value,
          onChanged: (v) => setValue(settings, v),
          sliderKey: ValueKey('$title-slider'),
          tooltipKey: ValueKey('$title-tooltip'),
          trackKey: ValueKey('$title-track'),
          formatValue: formatValue,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Natural scrolling ki sheet — switch ke saath.
void _openNaturalScrollSheet(BuildContext context) {
  _openSheet(
    context,
    title: 'Natural scrolling',
    child: const _NaturalScrollSheetContent(),
  );
}

class _NaturalScrollSheetContent extends StatelessWidget {
  const _NaturalScrollSheetContent();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Natural scrolling',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                'Scroll direction ulat kar dein',
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: settings.naturalScroll,
          onChanged: settings.setNaturalScroll,
        ),
      ],
    );
  }
}

/// Appearance ki sheet — Dark / Light options, check ke saath.
void _openAppearanceSheet(BuildContext context) {
  _openSheet(
    context,
    title: 'Appearance',
    child: const _AppearanceSheetContent(),
  );
}

class _AppearanceSheetContent extends StatelessWidget {
  const _AppearanceSheetContent();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _OptionRow(
          icon: Icons.dark_mode_outlined,
          label: 'Dark',
          selected: settings.isDark,
          onTap: () {
            settings.setDark(true);
            Navigator.of(context).pop();
          },
        ),
        _OptionRow(
          icon: Icons.light_mode_outlined,
          label: 'Light',
          selected: !settings.isDark,
          onTap: () {
            settings.setDark(false);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 24, color: scheme.onSurface),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, size: 24, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// About ki sheet.
void _openAboutSheet(BuildContext context) {
  _openSheet(
    context,
    title: 'About Mousify',
    child: const _AboutSheetContent(),
  );
}

class _AboutSheetContent extends StatelessWidget {
  const _AboutSheetContent();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Mousify',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Version 1.0.0',
          style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          'Made by Aorigoon',
          style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Text(
          'Your phone is the mouse now — turn it into a trackpad '
          'and keyboard for your PC.',
          style: TextStyle(fontSize: 14, color: scheme.onSurface, height: 1.5),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Nearby servers ki sheet — discovery list, tap par connect.
void _openServersSheet(BuildContext context) {
  _openSheet(
    context,
    title: 'Nearby servers',
    child: _ServersSheet(parentContext: context),
  );
}

class _ServersSheet extends StatefulWidget {
  final BuildContext parentContext;

  const _ServersSheet({required this.parentContext});

  @override
  State<_ServersSheet> createState() => _ServersSheetState();
}

class _ServersSheetState extends State<_ServersSheet> {
  final MousifyDiscovery _discovery = MousifyDiscovery();

  @override
  void initState() {
    super.initState();
    _discovery.start();
  }

  @override
  void dispose() {
    _discovery.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: _discovery,
      builder: (context, _) {
        if (_discovery.servers.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                if (_discovery.scanning)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.wifi_find_outlined,
                    size: 22,
                    color: scheme.onSurfaceVariant,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _discovery.scanning
                        ? 'Searching for nearby PCs…'
                        : 'Koi nearby server nahi mila',
                    style: TextStyle(
                      fontSize: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (!_discovery.scanning)
                  TextButton(
                    onPressed: _discovery.start,
                    child: const Text('Scan again'),
                  ),
              ],
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._discovery.servers.map((s) {
              final isActive = settings.host == s.address &&
                  settings.port == s.port;
              return _ServerRow(
                server: s,
                isActive: isActive,
                onTap: () {
                  Navigator.of(context).pop();
                  _connectToServer(widget.parentContext, s);
                },
              );
            }),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _discovery.start,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Scan again'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ServerRow extends StatelessWidget {
  final DiscoveredServer server;
  final bool isActive;
  final VoidCallback onTap;

  const _ServerRow({
    required this.server,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.computer_outlined,
                size: 24,
                color: scheme.onSurface,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${server.address}:${server.port}',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Icon(Icons.check_circle, color: scheme.primary)
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Server par tap — host save karo, connect karo (dialogs ke saath).
Future<void> _connectToServer(
  BuildContext context,
  DiscoveredServer s,
) async {
  final settings = context.read<AppSettings>();
  settings.setHost(s.address, s.port);
  await _connectWithFeedback(
    context,
    s.address,
    s.port,
    token: settings.token,
  );
}

Future<void> _connectWithFeedback(
  BuildContext context,
  String host,
  int port, {
  String? token,
}) async {
  final conn = context.read<MousifyConnection>();
  conn.connect(host, port, token: token);

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
  if (!context.mounted) return;
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
