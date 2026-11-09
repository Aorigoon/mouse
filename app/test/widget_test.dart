import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mousify/main.dart';
import 'package:mousify/widgets/touchpad_area.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app boots to touchpad home (light theme default)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MousifyApp());
    await tester.pump(const Duration(milliseconds: 400));
    final pad = tester.getSize(find.byType(TouchpadArea));
    // layout regression guard: touchpad poora visible ho (zero-height bug)
    expect(pad.height, greaterThan(200));
    // Naya design: chhota MOUSIFY header + floating nav ke naye icons
    expect(find.text('MOUSIFY'), findsOneWidget);
    expect(find.byIcon(Icons.touch_app_rounded), findsWidgets);
    expect(find.byIcon(Icons.apps_rounded), findsOneWidget);
    expect(find.byIcon(Icons.handyman_rounded), findsOneWidget);
    expect(find.byIcon(Icons.settings_suggest_rounded), findsOneWidget);
  });
}
