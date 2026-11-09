import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mousify/main.dart';
import 'package:mousify/widgets/touchpad_area.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Real design screenshot — GitHub Actions me chalta hai.
///
/// `flutter test --update-goldens test/design_screenshot_test.dart`
/// se `test/goldens/home.png` banta hai — ye asli Flutter render hai,
/// AI preview nahi. Workflow usi file ko `screenshots/home.png`
/// me copy karke repo me wapas commit karta hai.
void main() {
  testWidgets('real design screenshot - home 390x844', (tester) async {
    SharedPreferences.setMockInitialValues({});

    // Phone size: 390x844 @ 2x
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MousifyApp());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(TouchpadArea), findsOneWidget);
    expect(find.text('MOUSIFY'), findsOneWidget);
    expect(find.text('Drag to move'), findsOneWidget);
    expect(find.byIcon(Icons.apps_rounded), findsOneWidget);
    expect(find.byIcon(Icons.handyman_rounded), findsOneWidget);
    expect(find.byIcon(Icons.settings_suggest_rounded), findsOneWidget);

    await expectLater(
      find.byType(MousifyApp),
      matchesGoldenFile('goldens/home.png'),
    );
  });
}
