import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Profile details — Settings > Profile page.
///
/// Naam/email AuthService se aate hain (Google account); ye store sirf
/// nickname rakhta hai ("What should we call you?"). Sab kuch device
/// par local hai (SharedPreferences), koi server nahi.
///
/// (v3 — simple: birthday/phone/home/work/family/photo hata diye gaye;
/// sirf nickname rehta hai.)
class ProfileStore extends ChangeNotifier {
  static const _kNickname = 'profile_nickname';

  String nickname = '';

  Future<void> get loaded => _loaded;
  late final Future<void> _loaded;

  ProfileStore() {
    _loaded = _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    nickname = prefs.getString(_kNickname) ?? '';
    notifyListeners();
  }

  Future<void> setNickname(String value) async {
    nickname = value.trim();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNickname, nickname);
  }
}
