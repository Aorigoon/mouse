import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Floating rounded bottom navigation — Mousify ka naya premium nav.
///
/// • Screen se upar floating pill, dono taraf gap, poora rounded (36px)
/// • Active tab: lime pill + black icon + label
/// • Inactive tab: soft grey rounded icon, sirf icon (label chhota)
/// • Glassy shadow + halki border, light/dark dono me khubsurat
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 72,
      margin: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        color: isDark
            ? const Color(0xFF1C1C1E).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.94),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.16),
            blurRadius: 28,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(child: _NavButton(
              item: _items[i],
              selected: i == currentIndex,
              onTap: () {
                HapticFeedback.selectionClick();
                onTap(i);
              },
            )),
        ],
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 16 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: selected
                ? const Color(0xFFD6FF3F)
                : Colors.transparent,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFFD6FF3F)
                          .withValues(alpha: 0.38),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? item.activeIcon : item.icon,
                size: 24,
                color: selected
                    ? Colors.black
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.55)
                        : Colors.black.withValues(alpha: 0.45)),
              ),
              if (selected) ...[
                const SizedBox(width: 7),
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 13.5,
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
