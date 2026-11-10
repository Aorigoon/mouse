import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mousify/main.dart';
import 'package:mousify/widgets/touchpad_area.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Touchpad dot grid golden — Zain ki reference image jaisi.
///
/// Finger dabao to poore touchpad par dots ki grid nazar aati hai:
/// finger ke qareeb dots bade aur gehre royal blue, bahar ki taraf
/// chhote aur halke — reference se thode chhote. Finger uthe to
/// grid gayab ho jata hai (pad bilkul saaf).
/// Real render hai — `flutter test --update-goldens` se banta hai.
void main() {
  // Fonts setUpAll me load karo — testWidgets ke fake-async zone me
  // FontLoader.load() atak jata hai.
  setUpAll(loadTestFonts);

  testWidgets('touchpad dot grid - royal blue dots around finger', (tester) async {
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

    // Finger ko touchpad par ek curve me chalao — grid finger ke
    // gird bade/ge hre dots dikhaye, bahar halke. (320ms long-press
    // timer pump ke baghair aage nahi badhta, is liye scroll mode
    // on nahi hota.)
    final center = tester.getCenter(find.byType(TouchpadArea));
    final gesture = await tester.startGesture(center);
    await tester.pump();
    await gesture.moveTo(center + const Offset(-70, -90));
    await tester.pump();
    await gesture.moveTo(center + const Offset(30, -150));
    await tester.pump();
    await gesture.moveTo(center + const Offset(100, -70));
    await tester.pump();

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/touchpad_dots.png'),
    );

    await gesture.up();
    await tester.pump();
  });

  testWidgets('touchpad dot grid - royal blue dots around finger (dark)', (tester) async {
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

    expect(find.byType(TouchpadArea), findsOneWidget);

    // Dark mode me bhi: grid finger ke gird, background pure black.
    final center = tester.getCenter(find.byType(TouchpadArea));
    final gesture = await tester.startGesture(center);
    await tester.pump();
    await gesture.moveTo(center + const Offset(-70, -90));
    await tester.pump();
    await gesture.moveTo(center + const Offset(30, -150));
    await tester.pump();
    await gesture.moveTo(center + const Offset(100, -70));
    await tester.pump();

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/touchpad_dots_dark.png'),
    );

    await gesture.up();
    await tester.pump();
  });
}
