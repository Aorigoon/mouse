import 'package:flutter/services.dart';

import '../connection/settings_store.dart';

/// Haptic feedback — Settings → Haptic feedback toggle se control
/// hoti hai (AppSettings.hapticFeedback, default ON).
///
/// App ki saari tap/impact haptics yahin se guzarti hain, taaki
/// toggle band ho to kuch bhi vibrate na kare. `hapticsEnabled`
/// static mirror hai — is liye helper ko BuildContext nahi chahiye.
class Haptics {
  static void click() {
    if (AppSettings.hapticsEnabled) HapticFeedback.selectionClick();
  }

  static void impact() {
    if (AppSettings.hapticsEnabled) HapticFeedback.mediumImpact();
  }
}
