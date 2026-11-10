import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/back_chip.dart';

/// Terms of Service / Privacy Policy / FAQ / About page — screenshot
/// wale design me (Muse app ki Terms page jaisi):
/// • Upar gol back button + bada left title
/// • Neeche bada gol card — andar title, italic effective date
///   (Terms/Privacy ke liye), phir content: numbered headings,
///   paragraphs, bullets.
/// Body plain text hai — "1. ..." wali lines headings banti hain,
/// "• ..." wali lines bullets, baaki paragraphs.
///
/// Text seedha aur sachha hai: Mousify koi data collect nahi karta,
/// account device par local hai.
class LegalPage extends StatelessWidget {
  final String title;
  final String body;

  /// Terms/Privacy ke liye — "Effective 10 November 2026".
  /// FAQ/About ke liye null (koi date line nahi).
  final String? effectiveDate;

  const LegalPage({
    super.key,
    required this.title,
    required this.body,
    this.effectiveDate,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final ink = scheme.onSurface;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gol back button — composer page wala khud banaya hua
              // arrow (shared BackChip).
              BackChip(onTap: () => Navigator.of(context).pop()),
              const SizedBox(height: 16),
              // Bada title.
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              // Card — andar title + date + content.
              Material(
                color: AppColors.raised(isDark),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (effectiveDate != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          effectiveDate!,
                          style: TextStyle(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ..._buildBody(body, ink),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Body ko blocks me todo: "1. ..." headings, "• ..." bullets,
  /// baaki paragraphs.
  List<Widget> _buildBody(String body, Color ink) {
    final widgets = <Widget>[];
    for (final raw in body.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 10));
        continue;
      }
      if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(
              line,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
          ),
        );
        continue;
      }
      if (line.startsWith('• ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•  ',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.65,
                    color: ink,
                  ),
                ),
                Expanded(
                  child: Text(
                    line.substring(2),
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.65,
                      color: ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            line,
            style: TextStyle(
              fontSize: 15,
              height: 1.65,
              color: ink,
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}

const String legalEffectiveDate = 'Effective 10 November 2026';

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

Questions? Contact us at contact@aorigoon.com.
''';

const String legalPrivacyText = '''
Mousify does not collect, store, or share your personal data on any server.

• Your account: when you sign in with Google, your name and email are stored only on your device, so the app can show your profile. Nothing is uploaded anywhere.
• Your computer: your phone connects directly to your own PC over your local Wi-Fi network. Pointer movements, clicks and keystrokes are sent only to that PC. They are never stored, logged, or transmitted elsewhere.
• No analytics, no ads, no third-party trackers.

Deleting your account removes your profile from this device. If you uninstall the app, all locally stored data goes with it.

Questions? Contact us at contact@aorigoon.com.
''';

const String faqText = '''
1. How do I connect my phone to my PC?
Make sure your phone and PC are on the same Wi-Fi network, then start the Mousify server on your PC. In the app, go to Settings, then Connection, and scan the QR code from the PC screen — or pick your PC from Nearby servers.

2. My phone and PC are not on the same Wi-Fi. What can I do?
Turn on your phone's mobile hotspot and connect your PC to it. Your phone and PC are then on the same network, and Mousify works as usual. USB tethering works the same way.

3. The cursor moves too fast or too slow. How do I fix it?
Tap the three dots on the Mouse page and drag the Mouse Speed slider — or change Pointer sensitivity in Settings. A lower value is slower and more precise.

4. How does voice typing work?
Open the Composer (Typing) page and tap the microphone. Your phone's own speech recognition turns your voice into text, which is typed on your PC live. No account or internet service is needed for this.

5. Do I need an account to use Mousify?
No. The app works fully as a guest. Signing in with Google is optional and only shows your name and profile in the app.

6. Is my data sent anywhere?
No. Your phone talks directly to your own PC over your local network. Nothing is uploaded to any server, and there are no analytics, ads, or trackers.

7. Which computers does Mousify work with?
Any Linux PC with the Mousify server running on it. The server and the app must be on the same network.
''';

const String aboutText = '''
Mousify turns your phone into a wireless trackpad and keyboard for your PC.

Version 1.0.0
Made by Aorigoon

Your phone is the mouse now — no clicker, no wires, just touch.

Questions? Contact us at contact@aorigoon.com.
''';
