import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mousify account — sirf "Continue with Google" se.
///
/// • Google sign-in asli hai (`google_sign_in` package) — kamyab sign-in
///   par Google account ka naam + email profile ban jata hai.
/// • Account device par local hai (koi server nahi): naam/email
///   SharedPreferences me save hote hain, password kahin nahi.
/// • Google sign-in chalne ke liye Firebase/Google Cloud ka OAuth
///   client chahiye (`google-services.json` in android/app) — uske
///   baghair sign-in `AuthException` deta hai, app crash nahi karti.
class MousifyUser {
  final String name;
  final String email;

  const MousifyUser({required this.name, required this.email});

  /// Avatar ke liye initials — "Zain Ul Abidin" -> "ZA".
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService extends ChangeNotifier {
  static const _kName = 'auth_name';
  static const _kEmail = 'auth_email';

  final Completer<void> _loadedCompleter = Completer<void>();
  Future<void> get loaded => _loadedCompleter.future;

  late SharedPreferences _prefs;
  bool _googleInitialized = false;
  MousifyUser? _user;

  MousifyUser? get currentUser => _user;
  bool get isSignedIn => _user != null;

  AuthService() {
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final name = _prefs.getString(_kName);
    final email = _prefs.getString(_kEmail);
    if (name != null && email != null) {
      _user = MousifyUser(name: name, email: email);
    }
    _loadedCompleter.complete();
    notifyListeners();
  }

  static String? validateName(String name) {
    if (name.trim().length < 2) return 'Please enter your full name';
    return null;
  }

  /// Google sign-in — `true` = signed in, `false` = user ne cancel kiya.
  /// OAuth client setup na ho to AuthException.
  Future<bool> signInWithGoogle() async {
    try {
      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize();
        _googleInitialized = true;
      }
      final account = await GoogleSignIn.instance.authenticate();
      await signInWithGoogleAccount(
        name: account.displayName ?? 'Mousify User',
        email: account.email,
      );
      return true;
    } on GoogleSignInException catch (e) {
      // Cancel = ghalti nahi, bas wapas.
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return false;
      }
      throw const AuthException(
        'Google sign-in is not set up yet. '
        'Add google-services.json from Firebase to enable it.',
      );
    } catch (_) {
      throw const AuthException(
        'Google sign-in is not set up yet. '
        'Add google-services.json from Firebase to enable it.',
      );
    }
  }

  /// Google account milne ke baad profile save karo — signInWithGoogle
  /// isko use karta hai; tests bhi isi se user banate hain.
  Future<void> signInWithGoogleAccount({
    required String name,
    required String email,
  }) async {
    final n = name.trim();
    final e = email.trim().toLowerCase();
    final nameError = validateName(n);
    if (nameError != null) throw AuthException(nameError);
    if (!e.contains('@')) {
      throw const AuthException('Invalid Google account email.');
    }
    await _prefs.setString(_kName, n);
    await _prefs.setString(_kEmail, e);
    _user = MousifyUser(name: n, email: e);
    notifyListeners();
  }

  /// Sign out — local profile device se hat jata hai (account server
  /// par nahi hai, is liye sign-out hi local profile ko clear karta
  /// hai). Dobara "Continue with Google" se wapas aa sakte ho.
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Local sign-out kabhi fail nahi hona chahiye.
    }
    await _prefs.remove(_kName);
    await _prefs.remove(_kEmail);
    _user = null;
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    final n = name.trim();
    final error = validateName(n);
    if (error != null) throw AuthException(error);
    if (_user == null) return;
    await _prefs.setString(_kName, n);
    _user = MousifyUser(name: n, email: _user!.email);
    notifyListeners();
  }

  /// Account hamesha ke liye delete.
  Future<void> deleteAccount() async {
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {
      // Local delete kabhi fail nahi hona chahiye.
    }
    await _prefs.remove(_kName);
    await _prefs.remove(_kEmail);
    _user = null;
    notifyListeners();
  }
}
