import 'dart:async';
import 'dart:ui' show ImageFilter;
import '../utils/haptics.dart';

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
import 'legal_page.dart';
import 'profile_page.dart';

/// Settings — Muse app ke Settings screenshot jaisa, v5.
///
/// • Upar blur header (iOS large title jaisa): bara left "Settings"
///   scroll hokar upar jata hai, upar ek blur (frosted) wali patti me
///   "Settings" center me aa jata hai.
/// • Pehla card — Profile box: Profile (avatar + naam + email,
///   tap → ProfilePage / AuthPage), Appearance, Haptic feedback
///   (seedha toggle, koi sheet nahi).
/// • Phir Connection, Mouse (Natural scrolling seedha toggle),
///   Legal (About, FAQ, Privacy Policy, Terms of Service, Contact —
///   Contact aakhir me).
/// • Har row: bare outline icon + title + chevron — koi subtitle
///   nahi (values bahar nahi dikhti — na 1.4, na 350 ms, na On/Off).
/// • Cards dark mode me gray hain (#262628, flat matte) — kaale nahi.
/// • Appearance sheet Composer ke actions sheet jaisi hai (koi title
///   ya X nahi — drag handle + ek raised card me Light/Dark/System).
/// • Free plan / Upgrade card nahi hai — Mousify ki koi subscription
///   nahi hai, is liye wo card copy nahi kiya.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final ScrollController _scrollController = ScrollController();
  bool _showBar = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show = _scrollController.offset > 48;
    if (show != _showBar) setState(() => _showBar = show);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = context.watch<AppSettings>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bada left title — screenshot jaisa. Scroll par
                  // upar chala jata hai, blur bar aa jata hai.
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 8, 4, 20),
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  // Section label — card ke upar "Profile" likha ho.
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  // ================= PROFILE BOX =================
                  // Profile + Appearance + Haptic feedback — ek hi card.
                  _GroupCard(
                    child: Column(
                      children: [
                        _ProfileRow(
                          onTap: () => _openProfile(context),
                        ),
                        const _RowDivider(indent: 82),
                        _SettingsRow(
                          icon: Icons.dark_mode_outlined,
                          title: 'Appearance',
                          onTap: () => _openAppearanceSheet(context),
                        ),
                        const _RowDivider(),
                        _ToggleRow(
                          icon: Icons.vibration_outlined,
                          title: 'Haptic feedback',
                          value: settings.hapticFeedback,
                          onChanged: settings.setHapticFeedback,
                          switchKey: const Key('haptic-feedback-switch'),
                        ),
                      ],
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
                          onTap: () => showConnectSheet(context),
                        ),
                        const _RowDivider(),
                        _SettingsRow(
                          icon: Icons.radar_outlined,
                          title: 'Nearby servers',
                          onTap: () => _openServersSheet(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ================= MOUSE =================
                  // Three-dot wali mouse sheet ki settings yahan bhi hain.
                  // Natural scrolling seedha toggle hai (koi sheet nahi).
                  _GroupCard(
                    child: Column(
                      children: [
                        _SettingsRow(
                          icon: Icons.speed_outlined,
                          title: 'Pointer sensitivity',
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
                        // Shake — baghair toggle wali row hai, is liye
                        // toggle wali rows (Natural scrolling, Motion
                        // Control) se UPAR hai, baaki chevron rows ke
                        // saath. Tap par bottom sheet khulti hai.
                        _SettingsRow(
                          icon: Icons.phone_android_rounded,
                          title: 'Shake',
                          onTap: () => _openShakeSheet(context),
                        ),
                        const _RowDivider(),
                        _ToggleRow(
                          icon: Icons.swap_vertical_circle_outlined,
                          title: 'Natural scrolling',
                          value: settings.naturalScroll,
                          onChanged: settings.setNaturalScroll,
                          switchKey: const Key('natural-scrolling-switch'),
                        ),
                        const _RowDivider(),
                        // Motion Control — seedha toggle row, koi arrow
                        // nahi. On ho to neeche Motion speed slider
                        // khud card me aa jata hai (koi sheet nahi).
                        _ToggleRow(
                          icon: Icons.screen_rotation_rounded,
                          title: 'Motion Control',
                          value: settings.motionControl,
                          onChanged: settings.setMotionControl,
                          switchKey:
                              const Key('motion-control-switch'),
                        ),
                        if (settings.motionControl) ...[
                          const _RowDivider(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              18,
                              10,
                              18,
                              12,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Motion speed',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      settings.motionSensitivity
                                          .toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SpeedSlider(
                                  min: 0.5,
                                  max: 2.0,
                                  value: settings.motionSensitivity,
                                  onChanged: settings.setMotionSensitivity,
                                  sliderKey: const Key(
                                    'settings-motion-speed-slider',
                                  ),
                                  tooltipKey: const Key(
                                    'settings-motion-speed-tooltip',
                                  ),
                                  trackKey: const Key(
                                    'settings-motion-speed-slider-track',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ================= ABOUT & LEGAL =================
                  // Ek hi card me: About, FAQ, Privacy Policy,
                  // Terms of Service, Contact (aakhir me).
                  _GroupCard(
                    child: Column(
                      children: [
                        _LegalRow(
                          title: 'About',
                          onTap: () => _openLegalPage(
                            context,
                            title: 'About Mousify',
                            body: aboutText,
                          ),
                        ),
                        const _LegalDivider(),
                        _LegalRow(
                          title: 'FAQ',
                          onTap: () => _openLegalPage(
                            context,
                            title: 'FAQ',
                            body: faqText,
                          ),
                        ),
                        const _LegalDivider(),
                        _LegalRow(
                          title: 'Privacy Policy',
                          onTap: () => _openLegalPage(
                            context,
                            title: 'Privacy Policy',
                            body: legalPrivacyText,
                            effectiveDate: legalEffectiveDate,
                          ),
                        ),
                        const _LegalDivider(),
                        _LegalRow(
                          title: 'Terms of Service',
                          onTap: () => _openLegalPage(
                            context,
                            title: 'Terms of Service',
                            body: legalTermsText,
                            effectiveDate: legalEffectiveDate,
                          ),
                        ),
                        const _LegalDivider(),
                        _LegalRow(
                          title: 'Contact',
                          trailing: Text(
                            _contactEmail,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          onTap: () => _copyContactEmail(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Blur header — scroll par fade-in hota hai (iOS jaisa):
            // frosted patti me "Settings" center me.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_showBar,
                child: AnimatedOpacity(
                  opacity: _showBar ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.72),
                          border: Border(
                            bottom: BorderSide(
                              color: scheme.outline.withValues(alpha: 0.2),
                              width: 0.5,
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
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

/// Profile row — tap par ProfilePage (signed in) ya AuthPage (guest).
void _openProfile(BuildContext context) {
  final user = context.read<AuthService>().currentUser;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => user != null ? const ProfilePage() : const AuthPage(),
    ),
  );
}

/// Bada gol card — dark mode me gray (#262628), flat matte.
class _GroupCard extends StatelessWidget {
  final Widget child;

  const _GroupCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: AppColors.raised(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Rows ke beech wali divider — icon ke baad se shuru (default 58).
/// Profile row ke baad avatar ke baad se (82).
class _RowDivider extends StatelessWidget {
  final double indent;

  const _RowDivider({this.indent = 58});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: indent,
      color: Theme.of(context).colorScheme.outline,
    );
  }
}

/// Profile box ki pehli row — simple profile icon + naam + email +
/// chevron. Avatar ki jagah seedha person icon hai (koi gol background
/// nahi) — baaki rows jaisa. Signed in: naam/email (AuthService).
/// Guest: simple "Profile" (koi "Guest" / "Sign in with Google" nahi).
/// Tap → ProfilePage / AuthPage.
class _ProfileRow extends StatelessWidget {
  final VoidCallback onTap;

  const _ProfileRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = context.watch<AuthService>().currentUser;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Haptics.click();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 24,
                color: scheme.onSurface,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Profile',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (user != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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

/// Toggle wali row — icon + title + seedha Switch (koi chevron,
/// koi sheet nahi). Title par tap bhi toggle karta hai.
class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Key? switchKey;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.switchKey,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: scheme.onSurface),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Haptics.click();
                onChanged(!value);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          Switch(
            key: switchKey,
            value: value,
            onChanged: (v) {
              Haptics.click();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

/// Screenshot jaisi row: bare outline icon + title + side me
/// chevron. Koi subtitle nahi — values bahar nahi dikhti.
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
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
                Haptics.click();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 24, color: scheme.onSurface),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
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

/// Legal card ki row — screenshot wale card jaisi: sirf title +
/// side me open-in-new icon (ya Contact ke liye email). Koi left
/// icon nahi.
class _LegalRow extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _LegalRow({
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Haptics.click();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              trailing ??
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 22,
                    color: scheme.onSurfaceVariant,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Legal card ke rows ke beech wali divider — title se shuru.
class _LegalDivider extends StatelessWidget {
  const _LegalDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 18,
      color: Theme.of(context).colorScheme.outline,
    );
  }
}

const String _contactEmail = 'contact@aorigoon.com';

/// Legal/FAQ/About page kholo — screenshot wali Terms page jaisa.
void _openLegalPage(
  BuildContext context, {
  required String title,
  required String body,
  String? effectiveDate,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => LegalPage(
        title: title,
        body: body,
        effectiveDate: effectiveDate,
      ),
    ),
  );
}

/// Contact email copy karo + batado.
void _copyContactEmail(BuildContext context) {
  Haptics.click();
  // Clipboard ka wait nahi karte — copy fire-and-forget hai, snackbar
  // turant dikhao. (Test env me Clipboard.setData ka Future kabhi
  // complete nahi hota, is liye await karna hang karta hai.)
  unawaited(
    Clipboard.setData(const ClipboardData(text: _contactEmail))
        .catchError((_) {}),
  );
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Email copied: contact@aorigoon.com'),
      behavior: SnackBarBehavior.floating,
    ),
  );
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  // Gol X close button — home sheets jaisa.
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.raised(isDark),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          Haptics.click();
                          Navigator.of(context).pop();
                        },
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: AppColors.ink(isDark),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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

/// Shake ki sheet — Pointer sensitivity wali sheet jaisi (title +
/// X): Shake master toggle, Mouse pad / Typing toggles, phir har
/// action ke liye count slider — hamara default SpeedSlider
/// (scroll speed / wheel sensitivity wala), 1–5 shakes.
void _openShakeSheet(BuildContext context) {
  _openSheet(
    context,
    title: 'Shake',
    child: const _ShakeSheetContent(),
  );
}

class _ShakeSheetContent extends StatelessWidget {
  const _ShakeSheetContent();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToggleRow(
          icon: Icons.phone_android_rounded,
          title: 'Shake',
          value: settings.shakeEnabled,
          onChanged: settings.setShakeEnabled,
          switchKey: const Key('shake-enabled-switch'),
        ),
        if (settings.shakeEnabled) ...[
          const _RowDivider(),
          _ToggleRow(
            icon: Icons.touch_app_rounded,
            title: 'Mouse pad',
            value: settings.shakeMouseEnabled,
            onChanged: settings.setShakeMouseEnabled,
            switchKey: const Key('shake-mouse-switch'),
          ),
          // Mouse pad on ho to uska slider seedha uske neeche
          // (Motion Control wala pattern) — off ho to gayab.
          if (settings.shakeMouseEnabled) ...[
            const _RowDivider(),
            _ShakeCountSlider(
              label: 'Mouse pad shakes',
              value: settings.shakeMouseCount,
              onChanged: settings.setShakeMouseCount,
              sliderKey: const Key('shake-mouse-count-slider'),
              tooltipKey: const Key('shake-mouse-count-tooltip'),
              trackKey: const Key('shake-mouse-count-track'),
            ),
          ],
          const _RowDivider(),
          _ToggleRow(
            icon: Icons.keyboard_outlined,
            title: 'Typing',
            value: settings.shakeComposerEnabled,
            onChanged: settings.setShakeComposerEnabled,
            switchKey: const Key('shake-composer-switch'),
          ),
          // Typing on ho to uska slider seedha uske neeche.
          if (settings.shakeComposerEnabled) ...[
            const _RowDivider(),
            _ShakeCountSlider(
              label: 'Typing shakes',
              value: settings.shakeComposerCount,
              onChanged: settings.setShakeComposerCount,
              sliderKey: const Key('shake-composer-count-slider'),
              tooltipKey: const Key('shake-composer-count-tooltip'),
              trackKey: const Key('shake-composer-count-track'),
            ),
          ],
        ],
      ],
    );
  }
}

/// Shake sheet ka count slider — label + value + hamara default
/// SpeedSlider (1–5, poora number).
class _ShakeCountSlider extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final Key sliderKey;
  final Key tooltipKey;
  final Key trackKey;

  const _ShakeCountSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.sliderKey,
    required this.tooltipKey,
    required this.trackKey,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SpeedSlider(
            min: 1,
            max: 5,
            value: value.toDouble(),
            onChanged: (v) => onChanged(v.round()),
            sliderKey: sliderKey,
            tooltipKey: tooltipKey,
            trackKey: trackKey,
            formatValue: (v) => '${v.round()}',
          ),
        ],
      ),
    );
  }
}

/// Appearance ki sheet — Composer ke typing page ke actions sheet
/// jaisi: koi title ya X nahi, sirf drag handle + EK raised gol
/// card me Light / Dark / System (icon + label, selected par check).
/// Tap par select + sheet band.
void _openAppearanceSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AppearanceSheet(),
  );
}

class _AppearanceSheet extends StatelessWidget {
  const _AppearanceSheet();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = AppColors.ink(isDark);
    return Material(
      color: AppColors.chip(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: SafeArea(
          top: false,
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
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.raised(isDark),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _AppearanceOptionRow(
                        icon: Icons.light_mode_outlined,
                        label: 'Light',
                        selected: settings.themeMode == ThemeMode.light,
                        onTap: () {
                          settings.setThemeMode(ThemeMode.light);
                          Navigator.of(context).pop();
                        },
                      ),
                      _sheetDivider(ink),
                      _AppearanceOptionRow(
                        icon: Icons.dark_mode_outlined,
                        label: 'Dark',
                        selected: settings.themeMode == ThemeMode.dark,
                        onTap: () {
                          settings.setThemeMode(ThemeMode.dark);
                          Navigator.of(context).pop();
                        },
                      ),
                      _sheetDivider(ink),
                      _AppearanceOptionRow(
                        icon: Icons.brightness_auto_outlined,
                        label: 'System',
                        selected: settings.themeMode == ThemeMode.system,
                        onTap: () {
                          settings.setThemeMode(ThemeMode.system);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetDivider(Color ink) => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: ink.withValues(alpha: 0.08),
      );
}

/// Appearance sheet ki ek row — icon + label + selected par check.
class _AppearanceOptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AppearanceOptionRow({
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
          Haptics.click();
          onTap();
        },
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
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
    final isDark = scheme.brightness == Brightness.dark;
    return ListenableBuilder(
      listenable: _discovery,
      builder: (context, _) {
        if (_discovery.servers.isEmpty) {
          // Khubsurat empty state — radar icon + text + Scan button.
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.raised(isDark),
                  ),
                  child: _discovery.scanning
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Icon(
                          Icons.radar_outlined,
                          size: 30,
                          color: scheme.onSurfaceVariant,
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  _discovery.scanning
                      ? 'Searching for nearby PCs…'
                      : 'Koi nearby server nahi mila',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _discovery.scanning
                      ? 'Aas paas ke PCs dhoond rahe hain'
                      : 'Phone aur PC ek hi Wi-Fi par hon',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (!_discovery.scanning) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      Haptics.click();
                      _discovery.start();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Scan again'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }
        // Servers mil gaye — ek raised gol card me rows.
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.raised(isDark),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < _discovery.servers.length; i++) ...[
                      if (i > 0)
                        Container(
                          height: 1,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 16),
                          color: AppColors.ink(isDark)
                              .withValues(alpha: 0.08),
                        ),
                      _ServerRow(
                        server: _discovery.servers[i],
                        isActive: settings.host ==
                                _discovery.servers[i].address &&
                            settings.port == _discovery.servers[i].port,
                        onTap: () {
                          Navigator.of(context).pop();
                          _connectToServer(
                            widget.parentContext,
                            _discovery.servers[i],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Haptics.click();
                  _discovery.start();
                },
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
          Haptics.click();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
