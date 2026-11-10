import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connection/server_connection.dart';
import '../theme.dart';
import 'toolbox_icon.dart';

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
/// ho rahi thin, uski jagah Undo (Ctrl+Z) hai; Cut Tools page
/// par abhi bhi maujood hai.
/// Tool dabane par stick khuli rehti hai (Select All → Copy
/// jaise chain kar sakte hain) — band sirf X se hoti hai.
class QuickToolsStick extends StatefulWidget {
  const QuickToolsStick({super.key});

  @override
  State<QuickToolsStick> createState() => _QuickToolsStickState();
}

class _QuickToolsStickState extends State<QuickToolsStick> {
  bool _expanded = false;

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _expanded = !_expanded);
  }

  void _tool(String key, {bool ctrl = false}) {
    HapticFeedback.selectionClick();
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
                          ? Icon(
                              Icons.close_rounded,
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
            icon: Icons.select_all_rounded,
            ink: ink,
            onTap: () => onTool('a', ctrl: true),
          ),
          const SizedBox(height: 4),
          _StickBtn(
            key: const Key('tool-copy'),
            icon: Icons.copy_rounded,
            ink: ink,
            onTap: () => onTool('c', ctrl: true),
          ),
          const SizedBox(height: 4),
          _StickBtn(
            key: const Key('tool-paste'),
            icon: Icons.content_paste_rounded,
            ink: ink,
            onTap: () => onTool('v', ctrl: true),
          ),
          const SizedBox(height: 4),
          _StickBtn(
            key: const Key('tool-undo'),
            icon: Icons.undo_rounded,
            ink: ink,
            onTap: () => onTool('z', ctrl: true),
          ),
          const SizedBox(height: 4),
          _StickBtn(
            key: const Key('tool-clear'),
            icon: Icons.backspace_rounded,
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
  final IconData icon;
  final Color ink;
  final VoidCallback onTap;

  const _StickBtn({
    super.key,
    required this.icon,
    required this.ink,
    required this.onTap,
  });

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
          child: Icon(icon, size: 24, color: ink),
        ),
      ),
    );
  }
}
