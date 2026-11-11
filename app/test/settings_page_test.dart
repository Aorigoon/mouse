import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mousify/auth/auth_service.dart';
import 'package:mousify/connection/settings_store.dart';
import 'package:mousify/main.dart';
import 'package:mousify/theme.dart';
import 'package:mousify/views/auth_page.dart';
import 'package:mousify/views/legal_page.dart';
import 'package:mousify/views/profile_page.dart';
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
    // Profile box — guest: simple "Profile" (koi "Guest" /
    // "Sign in with Google" nahi), Appearance, Haptic feedback toggle.
    // 'Profile' do dafa hai — section label + guest row.
    expect(find.text('Profile'), findsWidgets);
    expect(find.text('Guest'), findsNothing);
    expect(find.text('Sign in with Google'), findsNothing);
    expect(find.text('Haptic feedback'), findsOneWidget);
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
    // Profile box me naam + email dikhte hain.
    SharedPreferences.setMockInitialValues({
      'auth_name': 'Zain Ul Abidin',
      'auth_email': 'zain@example.com',
    });
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Zain Ul Abidin'), findsOneWidget);
    expect(find.text('zain@example.com'), findsOneWidget);
    expect(find.text('Guest'), findsNothing);

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/settings_logged_in.png'),
    );
  });

  testWidgets('settings page - scrolled, blur header golden',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    // Neeche scroll karo — bara title upar jaye, blur bar me
    // "Settings" center me aa jaye. pumpAndSettle zaroori hai —
    // bar ki 200ms fade animation poori ho, warna golden me bar
    // nazar nahi aata (single pump par animation abhi shuru hoti hai).
    await tester.drag(find.byType(SettingsView), const Offset(0, -400));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/settings_scrolled.png'),
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

    // Neeche scroll karo — legal card (About, FAQ, Privacy Policy,
    // Terms of Service, Contact — Contact aakhir me) dikhe.
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
    // Composer sheet jaisi — koi title nahi, ek card me 3 options.
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);

    // Dark select karo — sheet band ho jaye, theme dark ho jaye.
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(find.text('Dark'), findsNothing);
    expect(find.text('Light'), findsNothing);
    expect(find.text('System'), findsNothing);
    expect(find.text('Appearance'), findsOneWidget);
    final brightness =
        Theme.of(tester.element(find.byType(SettingsView))).brightness;
    expect(brightness, Brightness.dark);
  });

  testWidgets('settings sheet - Appearance sheet golden', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    expect(find.text('System'), findsOneWidget);

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/appearance_sheet.png'),
    );
  });

  testWidgets('settings row - Natural scrolling row toggle', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    // Sheet nahi khulti — row par seedha toggle hai. Page par do
    // Switch hain (Haptic + Natural), is liye row se scope karo.
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

  testWidgets('settings row - Haptic feedback row toggle', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    final hapticSwitch = find.descendant(
      of: find.ancestor(
        of: find.text('Haptic feedback'),
        matching: find.byType(Row),
      ),
      matching: find.byType(Switch),
    );
    expect(hapticSwitch, findsOneWidget);
    expect(tester.widget<Switch>(hapticSwitch).value, isTrue);

    await tester.tap(hapticSwitch);
    await tester.pump();
    expect(tester.widget<Switch>(hapticSwitch).value, isFalse);
  });

  testWidgets(
      'settings row - Motion Control toggle on karne par speed slider card me dikhta hai',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    // Shuru me Motion Control off — speed slider nahi dikhta.
    expect(find.text('Motion speed'), findsNothing);
    // Motion Control row par koi chevron/arrow nahi hai.
    final rowChevron = find.descendant(
      of: find.ancestor(
        of: find.text('Motion Control'),
        matching: find.byType(Row),
      ),
      matching: find.byIcon(Icons.chevron_right_rounded),
    );
    expect(rowChevron, findsNothing);

    final rowSwitch = find.byKey(const Key('motion-control-switch'));
    expect(rowSwitch, findsOneWidget);
    expect(tester.widget<Switch>(rowSwitch).value, isFalse);

    await tester.tap(rowSwitch);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(rowSwitch).value, isTrue);
    // Speed slider ab card ke andar hi dikhta hai — koi sheet nahi.
    expect(find.text('Motion speed'), findsOneWidget);
    expect(
      find.byKey(const Key('settings-motion-speed-slider-track')),
      findsOneWidget,
    );

    await tester.tap(rowSwitch);
    await tester.pump();
    expect(tester.widget<Switch>(rowSwitch).value, isFalse);
    expect(find.text('Motion speed'), findsNothing);
  });

  testWidgets('settings row - Shake: ek row hai, tap par sheet khulti hai',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    // Page par sirf ek Shake row hai (chevron wali) — koi inline
    // toggle ya slider nahi.
    expect(find.text('Shake'), findsOneWidget);
    expect(find.text('Mouse pad'), findsNothing);
    expect(find.text('Typing'), findsNothing);
    expect(find.byKey(const Key('shake-enabled-switch')), findsNothing);

    // Row par tap — Pointer sensitivity jaisi bottom sheet khule.
    await tester.ensureVisible(find.text('Shake'));
    await tester.tap(find.text('Shake'));
    await tester.pumpAndSettle();

    // Sheet me Shake / Mouse pad / Typing toggles (default ON) +
    // dono count sliders (SpeedSlider, 2 aur 4).
    expect(
      tester
          .widget<Switch>(find.byKey(const Key('shake-enabled-switch')))
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<Switch>(find.byKey(const Key('shake-mouse-switch')))
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<Switch>(find.byKey(const Key('shake-composer-switch')))
          .value,
      isTrue,
    );
    expect(find.text('Mouse pad shakes'), findsOneWidget);
    expect(find.text('Typing shakes'), findsOneWidget);
    expect(find.byKey(const Key('shake-mouse-count-track')), findsOneWidget);
    expect(
      find.byKey(const Key('shake-composer-count-track')),
      findsOneWidget,
    );
  });

  testWidgets('shake sheet - master off karne par action rows chhup jati hain',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    await tester.ensureVisible(find.text('Shake'));
    await tester.tap(find.text('Shake'));
    await tester.pumpAndSettle();

    final master = find.byKey(const Key('shake-enabled-switch'));
    await tester.tap(master);
    await tester.pump();

    expect(tester.widget<Switch>(master).value, isFalse);
    expect(find.text('Mouse pad'), findsNothing);
    expect(find.text('Typing'), findsNothing);
    expect(find.byKey(const Key('shake-mouse-count-track')), findsNothing);
    expect(find.byKey(const Key('shake-composer-count-track')), findsNothing);
  });

  testWidgets(
      'shake sheet - Typing off karne par sirf Mouse ka slider rehta hai',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    await tester.ensureVisible(find.text('Shake'));
    await tester.tap(find.text('Shake'));
    await tester.pumpAndSettle();

    final composer = find.byKey(const Key('shake-composer-switch'));
    await tester.tap(composer);
    await tester.pump();

    expect(tester.widget<Switch>(composer).value, isFalse);
    expect(find.byKey(const Key('shake-mouse-count-track')), findsOneWidget);
    expect(find.byKey(const Key('shake-composer-count-track')), findsNothing);
    expect(find.text('Mouse pad shakes'), findsOneWidget);
    expect(find.text('Typing shakes'), findsNothing);
  });

  testWidgets('shake sheet - Shake sheet golden', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    await tester.ensureVisible(find.text('Shake'));
    await tester.tap(find.text('Shake'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/shake_sheet.png'),
    );
  });

  test('shake counts - composer ka count hamesha mouse se zyada rehta hai',
      () async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();
    await settings.loaded;

    expect(settings.shakeEnabled, isTrue);
    expect(settings.shakeMouseCount, 2);
    expect(settings.shakeComposerCount, 4);

    // Mouse count 4 karo to composer khud 5 ho jata hai.
    settings.setShakeMouseCount(4);
    expect(settings.shakeMouseCount, 4);
    expect(settings.shakeComposerCount, 5);

    // Composer count 2 karo to mouse khud 1 ho jata hai.
    settings.setShakeComposerCount(2);
    expect(settings.shakeComposerCount, 2);
    expect(settings.shakeMouseCount, 1);
  });

  testWidgets('settings row - Profile tap se ProfilePage khulti hai',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'auth_name': 'Zain Ul Abidin',
      'auth_email': 'zain@example.com',
    });
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    await tester.tap(find.text('Zain Ul Abidin'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.text('zain@example.com'), findsWidgets);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);
    // v3 — simple: EK box me Nickname + Email + Sign out, Delete neeche.
    // Koi "Save changes" nahi, Birthday/Phone/Home/Work/Family nahi.
    expect(find.text('Save changes'), findsNothing);
    expect(find.text('Nickname'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Birthday'), findsNothing);
    expect(find.text('Phone'), findsNothing);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Work'), findsNothing);
    expect(find.text('Family'), findsNothing);
    // Arrows: page par ab koi chevron nahi — Nickname, Sign out
    // aur Delete account teeno ke baghair.
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    // Sign out center me hai (page 390 chauda, center 195).
    final signOutBox =
        find.text('Sign out').evaluate().first.renderObject as RenderBox;
    final signOutCenter =
        signOutBox.localToGlobal(signOutBox.size.center(Offset.zero));
    expect((signOutCenter.dx - 195).abs(), lessThan(2));
    // Delete account partition horizontally chhota hai, text center me.
    final deleteTextBox =
        find.text('Delete account').evaluate().first.renderObject as RenderBox;
    final deleteCenter =
        deleteTextBox.localToGlobal(deleteTextBox.size.center(Offset.zero));
    expect((deleteCenter.dx - 195).abs(), lessThan(2));
    final deleteCardBox = find
        .ancestor(
          of: find.text('Delete account'),
          matching: find.byWidgetPredicate(
            (w) => w is Material && w.shape is RoundedRectangleBorder,
          ),
        )
        .evaluate()
        .first
        .renderObject as RenderBox;
    expect(deleteCardBox.size.width, lessThan(300));
    final signOutCardBox = find
        .ancestor(
          of: find.text('Sign out'),
          matching: find.byWidgetPredicate(
            (w) => w is Material && w.shape is RoundedRectangleBorder,
          ),
        )
        .evaluate()
        .first
        .renderObject as RenderBox;
    expect(signOutCardBox.size.width, greaterThan(300));

    await expectLater(
      find.byType(ProfilePage),
      matchesGoldenFile('goldens/profile_page.png'),
    );
  });

  testWidgets('profile page - Nickname edit sheet se save hota hai',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'auth_name': 'Zain Ul Abidin',
      'auth_email': 'zain@example.com',
    });
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    await tester.tap(find.text('Zain Ul Abidin'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nickname'));
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('profile-edit-field-0'));
    expect(field, findsOneWidget);
    await tester.enterText(field, 'Zainu');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    // Sheet band, row me naya nickname dikhe.
    expect(find.text('Zainu'), findsOneWidget);
    expect(find.text('What should we call you?'), findsNothing);
  });

  testWidgets('settings row - Guest tap se AuthPage khulti hai',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await pumpApp(tester);
    await goToSettings(tester);

    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(AuthPage), findsOneWidget);
    expect(find.text('Your Phone Is the Mouse Now.'), findsOneWidget);
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
