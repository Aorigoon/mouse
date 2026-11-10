import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mousify/main.dart';
import 'package:mousify/widgets/apps_grid_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Tab badalne par keyboard band ho — Apps ke search field par focus
/// ho, phir Mouse tab par jao to primaryFocus null hona chahiye.
/// (Settings ke IP field par ye test pehle tha — wo field ab Connect
/// sheet ke andar hai, is liye search field se verify hota hai.
/// HomeShell tab change par unfocus karta hai.)
void main() {
  setUpAll(loadTestFonts);

  testWidgets('Mouse tab par switch karne se keyboard band hota hai',
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

    // Apps tab par jao.
    await tester.tap(find.byType(AppsGridIcon));
    await tester.pumpAndSettle();
    expect(find.text('Search apps'), findsOneWidget);

    // Search field par tap — focus milna chahiye, keyboard khulna chahiye.
    await tester.tap(find.byType(TextField));
    await tester.pump();
    final focusedNode = FocusManager.instance.primaryFocus;
    expect(focusedNode, isNotNull);
    expect(tester.testTextInput.isVisible, isTrue);

    // Mouse tab par wapas — field ka focus chhootna chahiye,
    // keyboard band hona chahiye.
    await tester.tap(find.byIcon(Icons.touch_app_rounded));
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, isNot(focusedNode));
    expect(tester.testTextInput.isVisible, isFalse);
  });
}
