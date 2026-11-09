import 'package:flutter/material.dart';

/// App palette — monochrome (iPhone-style), sirf ek chhota green dot
/// live/connected status ke liye. Koi multi-color nahi.
class AppColors {
  static const live = Color(0xFF22C55E);

  /// Aorigoon lime — floating nav ke active pill aur highlights ke liye.
  static const accent = Color(0xFFD6FF3F);
  static const accentGlow = Color(0xFFB8E62E);
}

/// Light default, dark available. Primary = black (light) / white (dark).
class AppTheme {
  static const _darkOutline = Color(0xFF262626);
  static const _darkSubtle = Color(0xFF9E9E9E);
  static const _darkRaised = Color(0xFF141414);
  static const _lightOutline = Color(0xFFE4E4E4);
  static const _lightSubtle = Color(0xFF6E6E6E);
  static const _lightRaised = Color(0xFFF5F5F5);

  static ThemeData dark() => _build(
        const ColorScheme.dark(
          primary: Colors.white,
          onPrimary: Colors.black,
          secondary: Colors.white,
          onSecondary: Colors.black,
          surface: Colors.black,
          onSurface: Colors.white,
          surfaceContainerHighest: _darkRaised,
          onSurfaceVariant: _darkSubtle,
          outline: _darkOutline,
          outlineVariant: _darkOutline,
          error: Colors.white,
          onError: Colors.black,
        ),
      );

  static ThemeData light() => _build(
        const ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Colors.black,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          surfaceContainerHighest: _lightRaised,
          onSurfaceVariant: _lightSubtle,
          outline: _lightOutline,
          outlineVariant: _lightOutline,
          error: Colors.black,
          onError: Colors.white,
        ),
      );

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
    );
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 16.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),
      dividerColor: scheme.outline,
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.surfaceContainerHighest,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.onSurface,
        inactiveTrackColor: scheme.outline,
        thumbColor: scheme.onSurface,
        overlayColor: Colors.transparent,
        trackHeight: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.onSurface, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.primary,
        contentTextStyle: TextStyle(color: scheme.onPrimary, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
