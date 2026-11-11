import 'package:flutter/material.dart';
import '../utils/haptics.dart';
import 'package:provider/provider.dart';

import '../connection/server_connection.dart';
import '../theme.dart';
import 'close_icon.dart';
import 'copy_icon.dart';
import 'delete_icon.dart';
import 'paste_icon.dart';
import 'select_all_icon.dart';
import 'toolbox_icon.dart';
import 'undo_icon.dart';

/// Home page ka quick-tools button — neeche-right, right-click
/// button ke upar. Trigger icon bottom nav wala ToolboxIcon hai.
///
/// Ye EK HI pill hai — tap par yahi pill seedha upar expand
/// hoti hai, koi alag partition/panel nahi aata. Chaudi bilkul
/// nahi badhti (54, jitni icon/button ki hai), sirf height
/// upar ki taraf badhti hai. Khulne par neeche wala icon cross
/// (X) ban jata hai (band karne ke liye) aur uske upar 5 quick
/// tools hain (Tools page ke editing tools — jo aam mouse ke
/// saath use hote hain), icon by icon, koi text nahi:
///   Select All, Copy, Paste, Undo, Clear (selection clear).
/// Kainchi (Cut) hata di — uske jaisi remove wali icons zyada
/// ho rahi thin, uski jagah Undo (Ctrl+Z) hai. Tools page ka
/// EDITING section bhi hata diya gaya hai (2026-11-11) — ye 5
/// tools ab sirf yahin (mouse page) par hain, Tools page par
/// duplicate nahi.
/// Tool dabane par stick khuli rehti hai (Select All → Copy
/// jaise chain kar sakte hain) — band sirf X se hoti hai.
///
/// `openStick` — media stick ke saath share hota hai taaki ek
/// waqt me sirf ek stick khuli ho (media khule to ye band).
/// Null ho to stick akeli kaam karti hai (purana behavior).
class QuickToolsStick extends StatefulWidget {
  final ValueNotifier<String?>? openStick;
  final String stickId;

  const QuickToolsStick({
    super.key,
    this.openStick,
    this.stickId = 'tools',
  });

  @override
  State<QuickToolsStick> createState() => _QuickToolsStickState();
}

class _QuickToolsStickState extends State<QuickToolsStick> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    widget.openStick?.addListener(_onOpenStickChanged);
  }

  @override
  void dispose() {
    widget.openStick?.removeListener(_onOpenStickChanged);
    super.dispose();
  }

  /// Media stick khuli to ye band ho jaye (ek waqt me ek hi stick).
  void _onOpenStickChanged() {
    if (widget.openStick?.value != widget.stickId && _expanded) {
      if (mounted) setState(() => _expanded = false);
    }
  }

  void _toggle() {
    Haptics.click();
    if (!_expanded) {
      setState(() => _expanded = true);
      widget.openStick?.value = widget.stickId;
    } else {
      setState(() => _expanded = false);
      if (widget.openStick?.value == widget.stickId) {
        widget.openStick?.value = null;
      }
    }
  }

  void _tool(String key, {bool ctrl = false}) {
    Haptics.click();
    context.read<MousifyConnection>().send({
      't': 'key',
      'k': key,
      'ctrl': ctrl,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = AppColors.ink(isDark);
    return Material(
      color: AppColors.raised(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(27),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tools — khulne par upar ki taraf aate hain.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.94, end: 1.0)
                        .animate(animation),
                    alignment: Alignment.bottomCenter,
                    child: child,
                  ),
                );
              },
              child: _expanded
                  ? _ToolsColumn(
                      key: const ValueKey('quick-tools-open'),
                      ink: ink,
                      onTool: _tool,
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('quick-tools-closed'),
                    ),
            ),
            // Trigger — band ho to toolbox, khuli ho to cross (X).
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                key: const Key('quick-tools-button'),
                customBorder: const CircleBorder(),
                onTap: _toggle,
                child: SizedBox(
                  width: 54,
                  height: 54,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.6, end: 1.0)
                                .animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _expanded
                          ? CloseIcon(
                              key: const ValueKey('quick-tools-close'),
                              size: 26,
                              color: ink,
                            )
                          : ToolboxIcon(
                              key: const ValueKey('quick-tools-toolbox'),
                              size: 24,
                              color: ink,
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

/// Stick ke 5 tool buttons — 54×54, sirf icon, koi text nahi.
class _ToolsColumn extends StatelessWidget {
  final Color ink;
  final void Function(String key, {bool ctrl}) onTool;

  const _ToolsColumn({
    super.key,
    required this.ink,
    required this.onTool,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StickBtn(
            key: const Key('tool-select-all'),
            // Lucide square-dashed — Material select_all ki jagah.
            // (Lucide par "box-select" nahi hai — 404.)
            iconWidget: SelectAllIcon(size: 20, color: ink),
            ink: ink,
            onTap: () => onTool('a', ctrl: true),
          ),
          const SizedBox(height: 4),
          _StickBtn(
            key: const Key('tool-copy'),
            // Zain ka diya hua Lucide copy icon — size 20, stroke
            // Lucide default 2.0 (22 par bada dikhta tha).
            iconWidget: CopyIcon(size: 20, color: ink),
            ink: ink,
            onTap: () => onTool('c', ctrl: true),
          ),
          const SizedBox(height: 4),
          _StickBtn(
            key: const Key('tool-paste'),
            // Lucide clipboard-paste (lucide.dev) — Material paste ki jagah.
            iconWidget: PasteIcon(size: 20, color: ink),
            ink: ink,
            onTap: () => onTool('v', ctrl: true),
          ),
          const SizedBox(height: 4),
          _StickBtn(
            key: const Key('tool-undo'),
            // Lucide undo-2 — Material undo ki jagah.
            iconWidget: UndoIcon(size: 20, color: ink),
            ink: ink,
            onTap: () => onTool('z', ctrl: true),
          ),
          const SizedBox(height: 4),
          _StickBtn(
            key: const Key('tool-clear'),
            // Lucide delete (backspace key + X, lucide.dev) — cross
            // wala Material backspace icon hata diya.
            iconWidget: DeleteIcon(size: 20, color: ink),
            ink: ink,
            onTap: () => onTool('backspace'),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

/// Stick ka ek tool button — 54×54, sirf icon.
class _StickBtn extends StatelessWidget {
  final IconData? icon;
  // Custom icon (jaise Zain ka Lucide copy) — IconData ki jagah.
  final Widget? iconWidget;
  final Color ink;
  final VoidCallback onTap;

  const _StickBtn({
    super.key,
    this.icon,
    this.iconWidget,
    required this.ink,
    required this.onTap,
  }) : assert(icon != null || iconWidget != null);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 54,
          height: 54,
          // Center zaroori hai — baghair iske SizedBox (54x54)
          // icon ko tight constraints deta hai aur CustomPaint
          // apni `size` (20) ki jagah 54x54 ban jata hai (is liye
          // size 20/22/40 sab ek jaise dikhte the). Center loose
          // constraints deta hai, to icon apni asli size par banta hai.
          child: Center(
            child: iconWidget ?? Icon(icon, size: 24, color: ink),
          ),
        ),
      ),
    );
  }
}
