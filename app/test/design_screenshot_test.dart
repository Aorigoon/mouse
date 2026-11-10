import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mousify/main.dart';
import 'package:mousify/views/composer_page.dart';
import 'package:mousify/views/dock_page.dart';
import 'package:mousify/widgets/apps_grid_icon.dart';
import 'package:mousify/widgets/floating_nav_bar.dart';
import 'package:mousify/widgets/quick_tools_stick.dart';
import 'package:mousify/widgets/toolbox_icon.dart';
import 'package:mousify/widgets/touchpad_area.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Real design screenshot — GitHub Actions me chalta hai.
///
/// `flutter test --update-goldens test/design_screenshot_test.dart`
/// se `test/goldens/home.png` banta hai — ye asli Flutter render hai,
/// AI preview nahi. Workflow usi file ko `screenshots/home.png`
/// me copy karke repo me wapas commit karta hai.
void main() {
  // Fonts setUpAll me load karo — testWidgets ke fake-async zone me
  // FontLoader.load() atak jata hai (engine callback pump nahi hota).
  setUpAll(loadTestFonts);

  testWidgets('real design screenshot - home 390x844', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();

    // Phone size: 390x844 @ 2x
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MousifyApp());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(TouchpadArea), findsOneWidget);
    // Header: right corner par icons wali pill (koi text nahi) —
    // test me offline, koi server nahi
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
    expect(find.byType(AppsGridIcon), findsOneWidget);
    // ToolboxIcon ab do jagah hai — nav Tools tab + quick-tools trigger.
    expect(
      find.descendant(
        of: find.byType(FloatingNavBar),
        matching: find.byType(ToolboxIcon),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(QuickToolsStick),
        matching: find.byType(ToolboxIcon),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.settings_suggest_rounded), findsOneWidget);

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/home.png'),
    );
  });

  testWidgets('real design screenshot - quick tools stick',
      (tester) async {
    // Home page par neeche-right wala toolbox button — tap par
    // YAHI pill seedha upar expand hoti hai (koi alag partition
    // nahi, 54 chaudi, 5 tool icons, neeche cross (X), koi text
    // nahi). Ye golden stick ki khuli hui haalat dikhata hai.
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();

    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MousifyApp());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const Key('quick-tools-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tool-select-all')), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/quick_tools_stick.png'),
    );
  });

  testWidgets('real design screenshot - guide chip expanded', (tester) async {
    // Guide chip — collapsed par sirf touch/hand icon; tap par left ki taraf
    // expand hokar 4 gestures dikhata hai. Top pill (wifi/three-dot)
    // se alag hai.
    SharedPreferences.setMockInitialValues({'is_dark': true});
    mockSensorsForTest();

    // Phone size: 390x844 @ 2x
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MousifyApp());
    await tester.pump(const Duration(milliseconds: 400));

    // Collapsed — sirf touch/hand chip, guide text nahi.
    expect(find.byKey(const Key('guide-chip')), findsOneWidget);
    expect(find.text('Drag'), findsNothing);

    // Tap — expand hokar guide dikhaye (square 2×2 grid, header me).
    await tester.tap(find.byKey(const Key('guide-chip')));
    await tester.pumpAndSettle();

    expect(find.text('Gestures'), findsOneWidget);
    expect(find.text('Drag'), findsOneWidget);
    expect(find.text('Tap'), findsOneWidget);
    expect(find.text('2× Tap'), findsOneWidget);
    expect(find.text('Hold+Drag'), findsOneWidget);
    expect(find.text('Scroll'), findsOneWidget);

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/guide_chip_expanded.png'),
    );
  });

  testWidgets('real design screenshot - home dark mode', (tester) async {
    // Dark mode pin karo — is golden ko purane home.png se compare
    // karke verify hota hai ke light-mode fix ne dark look nahi badla.
    SharedPreferences.setMockInitialValues({'is_dark': true});
    mockSensorsForTest();

    // Phone size: 390x844 @ 2x
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MousifyApp());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(TouchpadArea), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/home_dark.png'),
    );
  });

  testWidgets('real design screenshot - mouse controls sheet', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();

    // Phone size: 390x844 @ 2x
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MousifyApp());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Mouse Speed'), findsOneWidget);
    expect(find.text('Motion Control'), findsOneWidget);
    expect(find.byKey(const Key('speed-slider')), findsOneWidget);

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/mouse_settings_sheet.png'),
    );
  });

  testWidgets('real design screenshot - connect sheet', (tester) async {
    // Wifi icon par tap — Connect sheet khulni chahiye (three-dot
    // wali Settings sheet jaisi style): status + IP/port fields +
    // bada Connect button. Fields me values type karke dikhate hain
    // (saved host mock karne se app launch par auto-connect shuru
    // ho jata hai aur uske timers test teardown fail kar dete hain).
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();

    // Phone size: 390x844 @ 2x
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MousifyApp());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byIcon(Icons.wifi_off_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Connect to PC'), findsOneWidget);
    expect(find.text('Not connected'), findsOneWidget);
    // Scanner sab se pehle, header me koi X close nahi.
    expect(find.text('Scan QR code'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(find.text('PC IP address'), findsOneWidget);
    expect(find.text('Port'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '192.168.1.10');
    await tester.enterText(find.byType(TextField).last, '9898');
    await tester.pump();

    expect(find.text('192.168.1.10'), findsOneWidget);
    expect(find.text('9898'), findsOneWidget);

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/connect_sheet.png'),
    );
  });

  testWidgets('connect sheet - khaali IP par error, sheet khuli rehti hai',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();

    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MousifyApp());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byIcon(Icons.wifi_off_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Connect to PC'), findsOneWidget);

    // IP khaali — Connect dabao to error snackbar, sheet band na ho.
    await tester.tap(find.text('Connect'));
    await tester.pump();
    expect(
      find.text('Enter a valid IP and port (e.g. 192.168.1.10 : 9898)'),
      findsOneWidget,
    );
    expect(find.text('Connect to PC'), findsOneWidget);
  });

  testWidgets('real design screenshot - motion speed gradient slider',
      (tester) async {
    // Motion Control on — Motion speed slider (gradient, Mouse Speed
    // jaisa) dikhna chahiye.
    SharedPreferences.setMockInitialValues({'motion_control': true});
    mockSensorsForTest();

    // Phone size: 390x844 @ 2x
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MousifyApp());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Motion speed'), findsOneWidget);
    expect(find.byKey(const Key('motion-speed-slider')), findsOneWidget);

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/motion_speed_slider.png'),
    );
  });

  testWidgets('real design screenshot - composer page', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();

    // Phone size: 390x844 @ 2x
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MousifyApp());
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(TouchpadArea), findsOneWidget);

    // Composer page kholo (shake se khulta hai — test me seedha push karo).
    final ctx = tester.element(find.byType(TouchpadArea));
    Navigator.of(ctx).push(
      MaterialPageRoute<void>(builder: (_) => const ComposerPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Start writing…'), findsOneWidget);
    // Voice mic chip — neeche.
    expect(find.text('Tap to speak'), findsOneWidget);
    // Header: back chip + Enter chip (back wala arrow, vertically) +
    // horizontal three-dot chip (koi "Typing" text nahi). Enter chip
    // golden me dikhta hai — neeche ki taraf arrow.
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/composer_page.png'),
    );

    // Three-dot sheet kholo — pehle kuch likho taaki rows enabled dikhain.
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Re-type'), findsOneWidget);

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/composer_actions_sheet.png'),
    );
  });

  testWidgets('real design screenshot - composer keyboard open', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();

    // Phone size: 390x844 @ 2x
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MousifyApp());
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(TouchpadArea), findsOneWidget);

    // Composer page kholo (shake se khulta hai — test me seedha push karo).
    final ctx = tester.element(find.byType(TouchpadArea));
    Navigator.of(ctx).push(
      MaterialPageRoute<void>(builder: (_) => const ComposerPage()),
    );
    await tester.pumpAndSettle();

    // Kuch likho, phir keyboard kholo (viewInsets se simulate) —
    // mic chip keyboard ke upar aa jani chahiye.
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    expect(find.text('Tap to speak'), findsOneWidget);

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/composer_keyboard.png'),
    );
  });

  testWidgets('real design screenshot - composer listening', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    mockSpeechForTest();

    // Phone size: 390x844 @ 2x
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MousifyApp());
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(TouchpadArea), findsOneWidget);

    // Composer page kholo (shake se khulta hai — test me seedha push karo).
    final ctx = tester.element(find.byType(TouchpadArea));
    Navigator.of(ctx).push(
      MaterialPageRoute<void>(builder: (_) => const ComposerPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tap to speak'), findsOneWidget);

    // Mic chip par tap — mock speech true deta hai, listening shuru hoti hai.
    // (pumpAndSettle nahi — pulse/wave animations repeat karti hain.)
    await tester.tap(find.text('Tap to speak'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Listening…'), findsOneWidget);

    // Animation ko thoda chalne do, phir screenshot.
    await tester.pump(const Duration(milliseconds: 600));

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/composer_listening.png'),
    );
  });

  testWidgets('real design screenshot - apps search bar centered', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();

    // Phone size: 390x844 @ 2x
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MousifyApp());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Apps tab par jao.
    await tester.tap(find.byType(AppsGridIcon));
    await tester.pumpAndSettle();
    expect(find.byType(DockPage), findsOneWidget);

    // Search bar center me, bottom nav ke upar — centered pill.
    expect(find.text('Search apps'), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/apps_search.png'),
    );
  });

  testWidgets('real design screenshot - apps search bar focused above keyboard',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();

    // Phone size: 390x844 @ 2x
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MousifyApp());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Apps tab par jao, search bar par tap karo.
    await tester.tap(find.byType(AppsGridIcon));
    await tester.pumpAndSettle();
    expect(find.byType(DockPage), findsOneWidget);
    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 400));

    // Keyboard simulate — search bar keyboard ke upar overlay hona chahiye.
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Search apps'), findsOneWidget);
    // Keyboard khula ho to bottom nav chhupa hota hai (neeche slide
    // hokar) — search bar seedha keyboard ke upar hota hai: bar ka
    // neeche wala kinara keyboard ke top (844-300=544) se sirf ~16px
    // upar hona chahiye. Pehle ye ~120px upar hota tha (nav beech
    // me aa jata tha).
    final barBottom = tester.getBottomLeft(find.byType(TextField)).dy;
    expect(barBottom, greaterThan(500));

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/apps_search_keyboard.png'),
    );
  });
}
