import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mousify/auth/auth_service.dart';
import 'package:mousify/main.dart';
import 'package:mousify/theme.dart';
import 'package:mousify/views/auth_page.dart';
import 'package:mousify/views/legal_page.dart';
import 'package:mousify/views/settings_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Naya Settings page + auth flow — design goldens + end-to-end test.
///
/// `flutter test --update-goldens test/settings_page_test.dart`
/// se `test/goldens/settings*.png` aur `auth_login.png` bante hain.
void main() {
  setUpAll(loadTestFonts);

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MousifyApp());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> goToSettings(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.settings_suggest_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsView), findsOneWidget);
  }

  testWidgets('settings page - logged out', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Connection'), findsOneWidget);
    expect(find.text('Nearby servers'), findsOneWidget);
    expect(find.text('Pointer sensitivity'), findsOneWidget);
    expect(find.text('Scroll speed'), findsOneWidget);
    expect(find.text('Wheel sensitivity'), findsOneWidget);
    expect(find.text('Double-tap speed'), findsOneWidget);
    expect(find.text('Natural scrolling'), findsOneWidget);
    expect(find.text('Motion Control'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('FAQ'), findsOneWidget);
    expect(find.text('Contact'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/settings.png'),
    );
  });

  testWidgets('settings page - logged in', (tester) async {
    // Pehle se bana hua account — naam/email SharedPreferences me.
    // Profile card hata diya hai, is liye page logged out jaisa hi
    // dikhta hai — ye test sirf render check hai.
    SharedPreferences.setMockInitialValues({
      'auth_name': 'Zain Ul Abidin',
      'auth_email': 'zain@example.com',
    });
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    expect(find.text('Settings'), findsWidgets);

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/settings_logged_in.png'),
    );
  });

  testWidgets('auth page - sirf Continue with Google, koi email form nahi',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    // AuthPage seedha pump karo — Settings se profile card hata diya
    // hai, is liye wahan se navigate nahi hota.
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ChangeNotifierProvider(
          create: (_) => AuthService(),
          child: const AuthPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AuthPage), findsOneWidget);
    expect(find.text('Your Phone Is the Mouse Now.'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    // Terms/Privacy RichText spans hain — find.text Text widget dhoondta
    // hai, is liye RichText ka plain text check karo.
    final terms = find.byWidgetPredicate(
      (w) =>
          w is RichText &&
          w.text.toPlainText().contains('Terms of Service') &&
          w.text.toPlainText().contains('Privacy Policy'),
    );
    expect(terms, findsOneWidget);

    // Test env me OAuth setup nahi — tap par error banner aaye,
    // app crash na kare.
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.textContaining('not set up'), findsOneWidget);
    expect(find.byType(AuthPage), findsOneWidget);
  });

  testWidgets('settings page - legal card golden', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    // Neeche scroll karo — legal card (About, FAQ, Contact,
    // Privacy Policy, Terms of Service) dikhe.
    // scrollUntilVisible nahi — PageView bhi Scrollable hai, is liye
    // wo "Too many elements" deta hai; ensureVisible nearest
    // Scrollable (Settings page) ko scroll karta hai.
    await tester.ensureVisible(find.text('Terms of Service'));
    await tester.pump();

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/settings_legal_card.png'),
    );
  });

  testWidgets('settings legal card - Terms page golden', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    // Row neeche hai (fold ke neeche) — pehle visible karo, phir tap.
    await tester.ensureVisible(find.text('Terms of Service'));
    await tester.pump();
    await tester.tap(find.text('Terms of Service'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/legal_terms.png'),
    );
  });

  testWidgets('settings legal card - Privacy page golden', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    await tester.ensureVisible(find.text('Privacy Policy'));
    await tester.pump();
    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/legal_privacy.png'),
    );
  });

  testWidgets('settings legal card - FAQ page golden', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    await tester.ensureVisible(find.text('FAQ'));
    await tester.pump();
    await tester.tap(find.text('FAQ'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/legal_faq.png'),
    );
  });

  testWidgets('settings legal card - About page golden', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    await tester.ensureVisible(find.text('About'));
    await tester.pump();
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/legal_about.png'),
    );
  });

  testWidgets('settings row - Pointer sensitivity sheet + slider drag',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    // Row par tap — slider wali bottom sheet khule.
    await tester.tap(find.text('Pointer sensitivity'));
    await tester.pumpAndSettle();
    expect(find.text('Pointer sensitivity'), findsWidgets);
    expect(find.text('1.4'), findsWidgets);
    expect(
      find.byKey(const Key('Pointer sensitivity-track')),
      findsOneWidget,
    );

    // Slider ko right drag karo — value badhni chahiye.
    await tester.drag(
      find.byKey(const Key('Pointer sensitivity-track')),
      const Offset(100, 0),
    );
    await tester.pump();
    final tooltip = tester.widget<Text>(
      find.byKey(const Key('Pointer sensitivity-tooltip')),
    );
    expect(tooltip.data, isNot('1.4'));
    expect(find.text('1.4'), findsNothing);
  });

  testWidgets('settings sheet - Pointer sensitivity slider golden',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    await tester.tap(find.text('Pointer sensitivity'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/settings_slider_sheet.png'),
    );
  });

  testWidgets('settings row - Appearance sheet se Dark select hota hai',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    // Sheet me Dark/Light options hain (row par koi subtitle nahi).
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);

    // Dark select karo — sheet band ho jaye, row par kuch nahi badle.
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(find.text('Dark'), findsNothing);
    expect(find.text('Light'), findsNothing);
    expect(find.text('Appearance'), findsOneWidget);
  });

  testWidgets('settings row - Natural scrolling sheet me switch toggle',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    await tester.tap(find.text('Natural scrolling'));
    await tester.pumpAndSettle();
    expect(find.byType(Switch), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('settings row - Motion Control sheet me switch + speed slider',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    await tester.tap(find.text('Motion Control'));
    await tester.pumpAndSettle();
    expect(find.byType(Switch), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.text('Motion speed'), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.text('Motion speed'), findsOneWidget);
    expect(
      find.byKey(const Key('settings-motion-speed-slider-track')),
      findsOneWidget,
    );
  });

  testWidgets('settings legal card - Terms page khulti hai', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    await tester.ensureVisible(find.text('Terms of Service'));
    await tester.pump();
    await tester.tap(find.text('Terms of Service'));
    await tester.pumpAndSettle();
    expect(find.byType(LegalPage), findsOneWidget);
    expect(find.text('Effective 10 November 2026'), findsOneWidget);
    expect(find.text('1. What Mousify does'), findsOneWidget);
  });

  testWidgets('settings legal card - FAQ page khulti hai', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    await tester.ensureVisible(find.text('FAQ'));
    await tester.pump();
    await tester.tap(find.text('FAQ'));
    await tester.pumpAndSettle();
    expect(find.byType(LegalPage), findsOneWidget);
    expect(
      find.text('1. How do I connect my phone to my PC?'),
      findsOneWidget,
    );
  });

  testWidgets('settings legal card - Contact copies email', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    await tester.ensureVisible(find.text('Contact'));
    await tester.pump();
    await tester.tap(find.text('Contact'));
    // Clipboard.setData async hai — snackbar tab aata hai jab wo
    // complete ho (ya fail ho kar catch ho), is liye do pump.
    await tester.pump();
    await tester.pump();
    expect(
      find.text('Email copied: contact@aorigoon.com'),
      findsOneWidget,
    );
  });

  testWidgets('mouse sheet - Natural scrolling switch toggle',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);

    // Three-dot se mouse sheet kholo — Natural scrolling ab yahin hai.
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Natural scrolling'), findsOneWidget);
    expect(find.text('Scroll speed'), findsOneWidget);
    final naturalSwitch = find.descendant(
      of: find.ancestor(
        of: find.text('Natural scrolling'),
        matching: find.byType(Row),
      ),
      matching: find.byType(Switch),
    );
    expect(naturalSwitch, findsOneWidget);
    expect(tester.widget<Switch>(naturalSwitch).value, isFalse);

    await tester.tap(naturalSwitch);
    await tester.pump();
    expect(tester.widget<Switch>(naturalSwitch).value, isTrue);
  });

  testWidgets('settings row - Connection se Connect sheet khulti hai',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    await tester.tap(find.text('Connection'));
    await tester.pumpAndSettle();
    expect(find.text('Scan QR code'), findsOneWidget);
  });

  testWidgets('settings row - Nearby servers sheet khulti hai',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    await tester.tap(find.text('Nearby servers'));
    // pumpAndSettle nahi — sheet me scanning spinner (CircularProgress-
    // Indicator) hamesha animate karta hai, settle kabhi nahi hota.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Nearby servers'), findsWidgets);
    // Discovery test env me fail ho (platform channel nahi) ya scan
    // kare — dono me se ek state dikhni chahiye.
    final searching =
        find.text('Searching for nearby PCs…').evaluate().isNotEmpty;
    final none =
        find.text('Koi nearby server nahi mila').evaluate().isNotEmpty;
    expect(searching || none, isTrue);
  });

  testWidgets('auth page - login golden', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ChangeNotifierProvider(
          create: (_) => AuthService(),
          child: const AuthPage(),
        ),
      ),
    );
    // Hero image + G logo async load/decode hote hain — pehle runAsync
    // se precache karo (warna single-test run me photo golden me nahi
    // aati), phir frame pump karo.
    final context = tester.element(find.byType(AuthPage));
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/login-hero.jpg'),
        context,
      );
      await precacheImage(
        const AssetImage('assets/images/g-logo.png'),
        context,
      );
    });
    await tester.pumpAndSettle();

    expect(find.text('Your Phone Is the Mouse Now.'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);

    await expectLater(
      find.byType(AuthPage),
      matchesGoldenFile('goldens/auth_login.png'),
    );
  });
}
