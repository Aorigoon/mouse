import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_service.dart';
import '../auth/profile_store.dart';
import '../theme.dart';
import '../utils/haptics.dart';
import '../widgets/back_chip.dart';

/// Profile page — Settings ke profile card se khulta hai.
///
/// v3 — SIMPLE (Zain, 2026-11-11): ek simple sa page. Upar gol back
/// button + bara "Profile" title, phir simple person icon + naam.
/// **EK box** me teeno: Nickname, Email, Sign out. **Delete account
/// uske neeche** alag (permanently delete — confirm dialog ke saath).
/// Koi "Save changes" nahi; Nickname apni sheet me Done par save hota hai.
/// (v2 ke Birthday/Phone/Home/Work/Family fields aur photo pick hata diye.)
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  /// Nickname edit karne wali sheet — Done par save + band.
  Future<void> _openNicknameSheet(String current) async {
    final values = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditFieldSheet(
        title: 'Nickname',
        fields: [
          _EditField(
            label: 'Nickname',
            initial: current,
            hint: 'What should we call you?',
          ),
        ],
      ),
    );
    if (values == null || !mounted) return;
    await context.read<ProfileStore>().setNickname(values.first);
    Haptics.click();
  }

  Future<void> _signOut() async {
    await context.read<AuthService>().signOut();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'Your profile and saved password will be permanently deleted '
          'from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await context.read<AuthService>().deleteAccount();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = context.watch<AuthService>().currentUser;
    final profile = context.watch<ProfileStore>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gol back button — LegalPage wala pattern.
              BackChip(onTap: () => Navigator.of(context).pop()),
              const SizedBox(height: 16),
              // Bara title.
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              // Simple person icon — koi background, koi photo nahi.
              Center(
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 72,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              // Naam.
              Center(
                child: Text(
                  user?.name ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // EK box — Nickname, Email.
              _DetailCard(
                rows: [
                  _DetailRow(
                    label: 'Nickname',
                    value: _valueText(
                      profile.nickname,
                      'What should we call you?',
                      scheme,
                    ),
                    // Arrow nahi — row tap karke edit hoti hai, chevron
                    // ke baghair bhi.
                    showChevron: false,
                    onTap: () =>
                        _openNicknameSheet(profile.nickname),
                  ),
                  _DetailRow(
                    label: 'Email',
                    value: _valueText(
                      user?.email ?? '',
                      '',
                      scheme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Sign out — alag partition me, center me, arrow nahi.
              _DetailCard(
                rows: [
                  _DetailRow(
                    label: 'Sign out',
                    centered: true,
                    onTap: _signOut,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Delete account — neeche alag, chhota partition
              // (horizontally bhi chhota), text center me, arrow nahi.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: _DetailCard(
                  rows: [
                    _DetailRow(
                      label: 'Delete account',
                      labelColor: Colors.red,
                      compact: true,
                      centered: true,
                      showChevron: false,
                      onTap: _deleteAccount,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Value text — set ho to onSurface, khali ho to placeholder gray.
  Widget _valueText(String value, String placeholder, ColorScheme scheme) {
    final empty = value.isEmpty;
    return Text(
      empty ? placeholder : value,
      style: TextStyle(
        fontSize: 16,
        color: empty ? scheme.onSurfaceVariant : scheme.onSurface,
      ),
      textAlign: TextAlign.right,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Details ka card — raised gol card, rows ke beech divider.
class _DetailCard extends StatelessWidget {
  final List<_DetailRow> rows;

  const _DetailCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i < rows.length - 1) {
        children.add(
          Divider(
            height: 1,
            indent: 18,
            endIndent: 18,
            color: scheme.outline.withValues(alpha: 0.08),
          ),
        );
      }
    }
    return Material(
      color: AppColors.raised(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

/// Details ki ek row — label left, value right (value na ho to sirf
/// label). Tap ho to chevron aur InkWell ripple (jab tak showChevron
/// false na ho); display-only row (Email) par kuch nahi. `centered`
/// ho to label beech me hota hai (Sign out — koi arrow nahi).
class _DetailRow extends StatelessWidget {
  final String label;
  final Color? labelColor;
  final Widget? value;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool centered;
  final bool compact;

  const _DetailRow({
    required this.label,
    this.labelColor,
    this.value,
    this.onTap,
    this.showChevron = true,
    this.centered = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelWidget = Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: labelColor ?? scheme.onSurface,
      ),
    );
    final vertical = compact ? 10.0 : 14.0;
    final Widget content;
    if (centered) {
      content = Padding(
        padding: EdgeInsets.symmetric(vertical: vertical),
        child: Center(child: labelWidget),
      );
    } else {
      content = Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: vertical),
        child: Row(
          children: [
            labelWidget,
            const SizedBox(width: 16),
            if (value != null) Expanded(child: value!),
            if (onTap != null && showChevron) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: labelColor ?? scheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      );
    }
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Haptics.click();
          onTap!();
        },
        child: content,
      ),
    );
  }
}

/// Edit sheet ka ek field.
class _EditField {
  final String label;
  final String initial;
  final String hint;

  const _EditField({
    required this.label,
    required this.initial,
    required this.hint,
  });
}

/// Field edit karne wali bottom sheet — title + X, TextField(s),
/// Done button. Values list wapas deti hai (null = cancel).
class _EditFieldSheet extends StatefulWidget {
  final String title;
  final List<_EditField> fields;

  const _EditFieldSheet({required this.title, required this.fields});

  @override
  State<_EditFieldSheet> createState() => _EditFieldSheetState();
}

class _EditFieldSheetState extends State<_EditFieldSheet> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.fields
        .map((f) => TextEditingController(text: f.initial))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.chip(isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle.
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Title + X.
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Haptics.click();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.raised(isDark),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < widget.fields.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              TextField(
                key: Key('profile-edit-field-$i'),
                controller: _controllers[i],
                autofocus: i == 0,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: i == widget.fields.length - 1
                    ? TextInputAction.done
                    : TextInputAction.next,
                onSubmitted: (_) {
                  if (i == widget.fields.length - 1) {
                    Navigator.of(context).pop(
                      _controllers.map((c) => c.text).toList(),
                    );
                  }
                },
                decoration: InputDecoration(
                  labelText: widget.fields[i].label,
                  hintText: widget.fields[i].hint,
                  filled: true,
                  fillColor: AppColors.raised(isDark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: scheme.onSurface,
                      width: 1.4,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(
                    _controllers.map((c) => c.text).toList(),
                  );
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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
