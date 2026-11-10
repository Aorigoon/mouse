import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../auth/auth_service.dart';
import 'legal_page.dart';

/// Login page — sirf "Continue with Google".
///
/// Design (Zain ki reference image jaisa, mobile):
/// • Koi back button nahi — login screen par arrow nahi hota (system
///   back gesture se wapas jaya ja sakta hai).
/// • Peeche image: haath me phone, dot-grid trackpad — upar/neeche
///   kaala gradient taaki text parh sake, beech me phone dikhe.
/// • Header: sirf "Mousify" wordmark — O ki jagah hamara haath icon
///   (bottom nav wala Mouse icon), icon ke peeche koi background nahi.
/// • Headline "Your Phone Is the Mouse Now." — Sora (open source
///   display font), ExtraBold, tight spacing
/// • Neeche hamari tagline — reference se behtar, Mousify ki apni
/// • Continue with Google button — poori pill (sides se gol), na
///   center me na bilkul bottom me — neeche-middle me
/// • Sab se neeche terms + privacy policy wali line (tappable)
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  static const _font = 'PlusJakartaSans';
  static const _headlineFont = 'Sora';
  bool _busy = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    final auth = context.read<AuthService>();
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final ok = await auth.signInWithGoogle();
      if (!mounted) return;
      if (ok) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openLegal(String title, String body) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LegalPage(title: title, body: body),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Peeche image — haath me phone, dot-grid trackpad.
            Image.asset(
              'assets/images/login-hero.jpg',
              fit: BoxFit.cover,
            ),
            // Kaala gradient — upar gehra (headline + phone ke chips
            // ke upar, taaki text saaf parh sake), beech me halka
            // (phone dikhe), neeche halka (patti ka blur dikhe).
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0.95),
                    Color.fromRGBO(0, 0, 0, 0.85),
                    Color.fromRGBO(0, 0, 0, 0.45),
                    Color.fromRGBO(0, 0, 0, 0.10),
                    Color.fromRGBO(0, 0, 0, 0.30),
                    Color.fromRGBO(0, 0, 0, 0.55),
                  ],
                  stops: [0.0, 0.25, 0.38, 0.52, 0.72, 1.0],
                ),
              ),
            ),
            // Neeche kaali patti — blur ke andar (frosted), upar se bhi
            // waisi hi jaise upar ka gradient hai: patti Continue with
            // Google ke peeche tak upar jati hai, taake button bhi blur
            // par ho. Upar wala edge fade hai, koi seedhi line nahi.
            // Privacy policy bilkul neeche, isi patti ke andar.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 300,
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                  stops: [0.0, 0.28],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.55),
                      alignment: Alignment.bottomCenter,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                                color: Colors.white.withValues(alpha: 0.60),
                              ),
                              children: [
                                const TextSpan(
                                  text: 'By continuing, you agree to our ',
                                ),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _openLegal(
                                          'Terms of Service',
                                          legalTermsText,
                                        ),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _openLegal(
                                          'Privacy Policy',
                                          legalPrivacyText,
                                        ),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 10, 28, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header: sirf "Mousify" — O ki jagah haath icon.
                    // Icon akela hai, uske peeche koi background nahi.
                    const Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(text: 'M'),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Icon(
                              Icons.touch_app_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(text: 'usify'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Your Phone Is the Mouse Now.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: _headlineFont,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                        height: 1.08,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Turn your phone into a trackpad and keyboard — '
                      'no clicker, no wires, just touch.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    // Button neeche-middle me — na center, na bottom.
                    const Spacer(flex: 3),
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 18,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  fontFamily: _font,
                                  fontSize: 13.5,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Sirf Continue with Google — poori pill.
                    SizedBox(
                      height: 56,
                      child: Material(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _busy ? null : _signInWithGoogle,
                          child: _busy
                              ? const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Color(0xFF1F1F1F),
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/g-logo.png',
                                      width: 22,
                                      height: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        fontFamily: _font,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1F1F1F),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
