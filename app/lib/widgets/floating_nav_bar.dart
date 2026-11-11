import 'package:flutter/material.dart';
import '../utils/haptics.dart';

import '../theme.dart';
import 'apps_grid_icon.dart';

/// Floating rounded bottom navigation — Mousify ka naya premium nav.
///
/// • Patla aur chota pill: height 54, content ko tight hug karta hai —
///   gray background sirf icons ke aas paas, sideon par extra gap nahi
///   (lime pill ke peeche bhi sirf halki si jagah)
/// • Gray pill, white icons — black par gray modern lagta hai
/// • Icons paas paas: compact centered row, koi Expanded quarters nahi —
///   warna Mouse se Apps tak ka faasla bohot zyada lagta hai
/// • Active tab: white pill + black icon + label
/// • Inactive tab: soft grey-white icon, sirf icon
/// • Glassy shadow + halki border
class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // `final` hai, `const` nahi — Apps item ka customIcon ek closure hai.
  static final _items = [
    _NavItem(
      label: 'Mouse',
      icon: Icons.touch_app_rounded,
      activeIcon: Icons.touch_app_rounded,
    ),
    _NavItem(
      label: 'Apps',
      // Zain ki reference image wala 2x2 grid icon (3 squircle +
      // upar-right diamond) — Material apps_rounded nahi.
      customIcon: (color) => AppsGridIcon(color: color),
    ),
    _NavItem(
      label: 'Settings',
      icon: Icons.settings_suggest_rounded,
      activeIcon: Icons.settings_suggest_rounded,
      // Gear glyph box ke andar chhota banta hai — baaki icons se
      // chhota lagta tha, is liye iska size thoda bada hai.
      iconSize: 26,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Pill content ko tight hug kare: Align + min Row — koi fixed
    // side margin nahi, warna gray background sideon se bada lagta hai.
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 54,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
        // Dark me gray, light me raised gray — black par gray modern lagta hai.
        // Flat matte: koi border line, koi shadow/gloss nahi.
        color: AppColors.raised(isDark),
      ),
      // Icons paas paas, center me: Expanded quarters hataye — warna
      // icons ek dusre se bohot door bikhre hue lagte hain.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            _NavButton(
              item: _items[i],
              selected: i == currentIndex,
              onTap: () {
                Haptics.click();
                onTap(i);
              },
            ),
          ],
        ],
      ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData? icon;
  final IconData? activeIcon;
  // Material icon ka size (default 22). Glyph chhota bane to bada do.
  final double iconSize;
  // Custom icon ho to ye use hota hai (color = us waqt ka icon color).
  final Widget Function(Color color)? customIcon;

  const _NavItem({
    required this.label,
    this.icon,
    this.activeIcon,
    this.iconSize = 22,
    this.customIcon,
  });
}

class _NavButton extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    // Active pill safed hai (dono themes me) — us par icon/label
    // black rehte hain. Inactive icons theme ink (dark par white,
    // light par black), halke.
    final ink = AppColors.ink(
      Theme.of(context).brightness == Brightness.dark,
    );
    final selected = widget.selected;
    // Ek hi animation style poore nav me — 350ms, easeInOutCubic —
    // taaki tab badalte waqt koi jhatka na lage, sab kuch ek saath
    // aur smoothly badle.
    const duration = Duration(milliseconds: 350);
    const curve = Curves.easeInOutCubic;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      // Dabao to halka sa chhota ho — tactile feedback.
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Center(
          child: AnimatedContainer(
            duration: duration,
            curve: curve,
            padding: EdgeInsets.symmetric(
              horizontal: selected ? 10 : 8,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: selected ? AppColors.accent : Colors.transparent,
              // Active pill par koi glow/shadow nahi — flat white.
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon halka sa bada ho jab active ho — subtle pop.
                // Custom icon (Apps grid) ho to wahi, warna Material icon.
                AnimatedScale(
                  scale: selected ? 1.12 : 1.0,
                  duration: duration,
                  curve: Curves.easeOutBack,
                  child: widget.item.customIcon != null
                      ? widget.item.customIcon!(
                          selected ? Colors.black : ink.withValues(alpha: 0.55),
                        )
                      : Icon(
                          selected ? widget.item.activeIcon : widget.item.icon,
                          size: widget.item.iconSize,
                          // Inactive icons halke ink
                          color: selected
                              ? Colors.black
                              : ink.withValues(alpha: 0.55),
                        ),
                ),
                // Label achanak nahi aata — width smoothly badhti hai
                // (AnimatedSize) aur fade hota hai (AnimatedOpacity),
                // is liye pill jump nahi karta.
                AnimatedSize(
                  duration: duration,
                  curve: curve,
                  alignment: Alignment.centerLeft,
                  clipBehavior: Clip.hardEdge,
                  child: AnimatedOpacity(
                    opacity: selected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: selected
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 6),
                              Text(
                                widget.item.label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox(width: 0),
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
