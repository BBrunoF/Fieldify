import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> pumpTestApp(
  WidgetTester tester,
  Widget child, {
  NavigatorObserver? navigatorObserver,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  final navigatorObservers = navigatorObserver == null
      ? const <NavigatorObserver>[]
      : <NavigatorObserver>[navigatorObserver];

  await tester.pumpWidget(
    MaterialApp(home: child, navigatorObservers: navigatorObservers),
  );
  await tester.pump();
}
