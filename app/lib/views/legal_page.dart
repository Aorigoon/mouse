import 'package:flutter/material.dart';

/// Terms of Service / Privacy Policy page — login page ki neeche wali
/// line se khulta hai. Text seedha aur sachha hai: Mousify koi data
/// collect nahi karta, account device par local hai.
class LegalPage extends StatelessWidget {
  final String title;
  final String body;

  const LegalPage({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Text(
            body,
            style: TextStyle(
              fontSize: 15,
              height: 1.65,
              color: scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

const String legalTermsText = '''
Welcome to Mousify. By using the app, you agree to these terms.

1. What Mousify does
Mousify turns your phone into a wireless trackpad and keyboard for your own computer over your local Wi-Fi network.

2. Your responsibility
Use Mousify only with computers you own or have permission to control. You are responsible for keeping your device and your Google account safe.

3. Your account
Signing in with Google only shares your name and email with the app on this device so it can show your profile. Your account lives on your device — there is no Mousify server storing it.

4. Availability
Mousify is provided "as is", without warranties of any kind. Features may change or improve over time.

5. Changes
We may update these terms from time to time. Continued use of the app after an update means you accept the new terms.

Questions? Contact Aorigoon.
''';

const String legalPrivacyText = '''
Mousify Privacy Policy

Mousify does not collect, store, or share your personal data on any server.

• Your account: when you sign in with Google, your name and email are stored only on your device, so the app can show your profile. Nothing is uploaded anywhere.
• Your computer: your phone connects directly to your own PC over your local Wi-Fi network. Pointer movements, clicks and keystrokes are sent only to that PC. They are never stored, logged, or transmitted elsewhere.
• No analytics, no ads, no third-party trackers.

Deleting your account removes your profile from this device. If you uninstall the app, all locally stored data goes with it.

Questions? Contact Aorigoon.
''';
