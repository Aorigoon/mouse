import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Floating rounded bottom navigation — Mousify ka naya premium nav.
///
/// • Patla aur chota pill: height 54, content ko tight hug karta hai —
///   gray background sirf icons ke aas paas, sideon par extra gap nahi
///   (lime pill ke peeche bhi sirf halki si jagah)
/// • Gray pill, white icons — black par gray modern lagta hai
/// • Icons paas paas: compact centered row, koi Expanded quarters nahi —
///   warna Mouse se Apps tak ka faasla bohot zyada lagta hai
/// • Active tab: lime pill + black icon + label
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

  static const _items = [
    _NavItem(
      label: 'Mouse',
      icon: Icons.touch_app_rounded,
      activeIcon: Icons.touch_app_rounded,
    ),
    _NavItem(
      label: 'Apps',
      icon: Icons.apps_rounded,
      activeIcon: Icons.apps_rounded,
    ),
    _NavItem(
      label: 'Tools',
      icon: Icons.handyman_rounded,
      activeIcon: Icons.handyman_rounded,
    ),
    _NavItem(
      label: 'Settings',
      icon: Icons.settings_suggest_rounded,
      activeIcon: Icons.settings_suggest_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
        // Dono themes me gray — black par gray modern lagta hai.
        // Flat matte: koi border line, koi shadow/gloss nahi.
        color: AppColors.surfaceGray,
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
                HapticFeedback.selectionClick();
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
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 10 : 8,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected
                ? AppColors.accent
                : Colors.transparent,
            // Active pill par koi glow/shadow nahi — flat white.
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? item.activeIcon : item.icon,
                size: 22,
                // Gray pill par inactive icons halke white
                color: selected
                    ? Colors.black
                    : Colors.white.withValues(alpha: 0.55),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: Colors.black,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
