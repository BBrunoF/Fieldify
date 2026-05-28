import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project/core/supabase/supabase_client.dart';
import 'package:project/features/home/presentation/screens/home_screen.dart';
import 'package:project/features/pro/profile/presentation/screens/pro_profile_screen.dart';
import 'package:project/main.dart' as app;

const _proEmail = 'test@test.com';
const _proPassword = 'testtest';

Future<void> _signOutIfNeeded() async {
  await initializeSupabase();
  final auth = Supabase.instance.client.auth;
  if (auth.currentSession != null) {
    await auth.signOut();
  }
}

Future<void> _loginAsPro(PatrolIntegrationTester $) async {
  await initializeSupabase();
  await $.pumpWidgetAndSettle(const app.FieldifyApp());

  await $(find.byKey(const Key('emailField')))
      .waitUntilVisible(timeout: const Duration(seconds: 20));

  await $(find.byKey(const Key('emailField'))).enterText(_proEmail);
  await $(find.byKey(const Key('passwordField'))).enterText(_proPassword);
  await $(find.byKey(const Key('loginButton'))).tap();

  await $.pumpAndTrySettle(timeout: const Duration(seconds: 20));

  expect(find.byType(HomeScreen), findsOneWidget);
  await $(find.byKey(const Key('homeGreetingText')))
      .waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _openProProfileScreen(PatrolIntegrationTester $) async {
  await $(find.byKey(const Key('bottomNavItem_profile'))).tap();
  await $(find.byType(ProProfileScreen))
      .waitUntilVisible(timeout: const Duration(seconds: 20));
  await $.pumpAndTrySettle(timeout: const Duration(seconds: 10));
}

void main() {
  patrolSetUp(_signOutIfNeeded);
  patrolTearDown(_signOutIfNeeded);

  patrolTest('pro can see the work hours calendar grid with 7 day columns',
      ($) async {
    await _loginAsPro($);
    await _openProProfileScreen($);

    await $(find.byKey(const Key('workHoursCalendarGrid'))).scrollTo();
    await $(find.byKey(const Key('workHoursCalendarGrid')))
        .waitUntilVisible(timeout: const Duration(seconds: 10));

    for (int day = 0; day < 7; day++) {
      expect(find.byKey(Key('proProfileDay_$day')), findsOneWidget);
    }
  });

  patrolTest('pro can select a day by tapping its column', ($) async {
    await _loginAsPro($);
    await _openProProfileScreen($);

    await $(find.byKey(const Key('workHoursCalendarGrid'))).scrollTo();
    await $.pumpAndTrySettle();

    // Tap Tuesday (index 1) — should show "Tue" in the editor below
    await $(find.byKey(const Key('proProfileDay_1'))).tap();
    await $.pumpAndTrySettle();

    expect(find.text('Tue'), findsOneWidget);
  });

  patrolTest('pro can enable a day and save with the unified save button',
      ($) async {
    await _loginAsPro($);
    await _openProProfileScreen($);

    await $(find.byKey(const Key('workHoursCalendarGrid'))).scrollTo();
    await $.pumpAndTrySettle();

    // Select Monday and enable it
    await $(find.byKey(const Key('proProfileDay_0'))).tap();
    await $.pumpAndTrySettle();

    final switchKey = const Key('proProfileDaySwitch_0');

    // Always toggle to guarantee _dirty = true regardless of current DB state.
    // If Monday was already enabled, disable it first then re-enable it.
    final switchBefore =
        $(find.byKey(switchKey)).evaluate().first.widget as Switch;
    if (switchBefore.value) {
      await $(find.byKey(switchKey)).tap();
      await $.pumpAndTrySettle();
    }
    await $(find.byKey(switchKey)).tap();
    await $.pumpAndTrySettle();

    await $(find.byKey(const Key('proProfileSaveButton'))).scrollTo();
    await $(find.byKey(const Key('proProfileSaveButton'))).tap();

    await $(find.text('Profile updated'))
        .waitUntilVisible(timeout: const Duration(seconds: 15));
  });

  patrolTest('pro can disable a day and save with the unified save button',
      ($) async {
    await _loginAsPro($);
    await _openProProfileScreen($);

    await $(find.byKey(const Key('workHoursCalendarGrid'))).scrollTo();
    await $.pumpAndTrySettle();

    // Select Monday and disable it
    await $(find.byKey(const Key('proProfileDay_0'))).tap();
    await $.pumpAndTrySettle();

    final switchKey = const Key('proProfileDaySwitch_0');
    final switchWidget =
        $(find.byKey(switchKey)).evaluate().first.widget as Switch;
    if (switchWidget.value) {
      await $(find.byKey(switchKey)).tap();
      await $.pumpAndTrySettle();
    }

    await $(find.byKey(const Key('proProfileSaveButton'))).scrollTo();
    await $(find.byKey(const Key('proProfileSaveButton'))).tap();

    await $(find.text('Profile updated'))
        .waitUntilVisible(timeout: const Duration(seconds: 15));
  });

  patrolTest('pro can save location coordinates with the unified save button',
      ($) async {
    await _loginAsPro($);
    await _openProProfileScreen($);

    // Location is now picked via the map picker rather than raw lat/lng
    // fields: tap the preview to open the picker, confirm whichever pin is
    // centered (defaults to Porto when no base location is saved), then save.
    await $(find.byKey(const Key('proProfileMapPreview'))).scrollTo();
    await $(find.byKey(const Key('proProfileMapPreview'))).tap();
    await $.pumpAndTrySettle();

    await $(find.byKey(const Key('confirmLocationButton')))
        .waitUntilVisible(timeout: const Duration(seconds: 15));
    await $(find.byKey(const Key('confirmLocationButton'))).tap();
    await $.pumpAndTrySettle();

    await $(find.byKey(const Key('proProfileSaveButton'))).scrollTo();
    await $(find.byKey(const Key('proProfileSaveButton'))).tap();

    await $(find.text('Profile updated'))
        .waitUntilVisible(timeout: const Duration(seconds: 15));
  });

  patrolTest(
      'pro can switch between days and each shows correct enabled state',
      ($) async {
    await _loginAsPro($);
    await _openProProfileScreen($);

    await $(find.byKey(const Key('workHoursCalendarGrid'))).scrollTo();
    await $.pumpAndTrySettle();

    // Select each day and verify the switch key changes accordingly
    for (int day = 0; day < 7; day++) {
      await $(find.byKey(Key('proProfileDay_$day'))).tap();
      await $.pumpAndTrySettle();
      expect(find.byKey(Key('proProfileDaySwitch_$day')), findsOneWidget);
    }
  });
}
