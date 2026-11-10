import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mousify/main.dart';
import 'package:mousify/widgets/apps_grid_icon.dart';
import 'package:mousify/widgets/toolbox_icon.dart';
import 'package:mousify/widgets/touchpad_area.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('app boots to touchpad home (light theme default)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await tester.pumpWidget(const MousifyApp());
    await tester.pump(const Duration(milliseconds: 400));
    final pad = tester.getSize(find.byType(TouchpadArea));
    // layout regression guard: touchpad poora visible ho (zero-height bug)
    expect(pad.height, greaterThan(200));
    // Naya design: right corner par icons wali pill (wifi-off + three-dot)
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
    expect(find.byIcon(Icons.touch_app_rounded), findsWidgets);
    expect(find.byType(AppsGridIcon), findsOneWidget);
    expect(find.byType(ToolboxIcon), findsOneWidget);
    expect(find.byIcon(Icons.settings_suggest_rounded), findsOneWidget);
  });

  testWidgets('mouse speed slider lives on the settings sheet',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await tester.pumpWidget(const MousifyApp());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Mouse Speed'), findsOneWidget);
    expect(find.text('Motion Control'), findsOneWidget);
    expect(find.byKey(const Key('speed-slider')), findsOneWidget);
    // '1.4' do jagah hai — label wali value + (chhupa hua) tooltip
    expect(find.text('1.4'), findsNWidgets(2));

    // Slider ko right drag karo — speed badhni chahiye, tooltip dikhna
    // chahiye, aur label wali value bhi saath badalni chahiye
    await tester.drag(
      find.byKey(const Key('speed-slider-track')),
      const Offset(100, 0),
    );
    await tester.pump();
    final tooltip =
        tester.widget<Text>(find.byKey(const Key('speed-tooltip')));
    expect(tooltip.data, isNot('1.4'));
    expect(find.text('1.4'), findsNothing);
  });

  testWidgets('motion control toggle shows motion speed slider',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSensorsForTest();
    await tester.pumpWidget(const MousifyApp());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Motion speed'), findsNothing);
    // Sheet me do switches hain (Natural scrolling + Motion Control) —
    // Motion Control wala hi tap karo (uski row ke andar wala Switch).
    final motionSwitch = find.descendant(
      of: find.ancestor(
        of: find.text('Motion Control'),
        matching: find.byType(Row),
      ),
      matching: find.byType(Switch),
    );
    expect(motionSwitch, findsOneWidget);
    await tester.tap(motionSwitch);
    await tester.pumpAndSettle();
    expect(find.text('Motion speed'), findsOneWidget);
  });
}
