import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:service_app/main.dart';

void main() {
  testWidgets('App builds a MaterialApp', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ServiceApp());
    expect(find.byType(MaterialApp), findsOneWidget);

    // Let the splash screen's 2s delay elapse so no timer is left pending.
    await tester.pump(const Duration(seconds: 3));
  });
}
