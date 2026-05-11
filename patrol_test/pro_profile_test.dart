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

Future<void> _bootstrapSupabase() async {
  await initializeSupabase();
}

Future<void> _signOutIfNeeded() async {
  await _bootstrapSupabase();
  final auth = Supabase.instance.client.auth;
  if (auth.currentSession != null) {
    await auth.signOut();
  }
}

Future<void> _loginAsPro(PatrolIntegrationTester $) async {
  await _bootstrapSupabase();
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

// Scrolls the bio field into view, clears it, then enters the given text.
// Required because the bio field is at the bottom of a long scrollable form
// and may already contain the target value from a previous test run.
Future<void> _enterBioText(PatrolIntegrationTester $, String text) async {
  await $(find.byKey(const Key('proProfileBioField'))).scrollTo();
  await $(find.byKey(const Key('proProfileBioField'))).enterText('');
  await $.pumpAndTrySettle();
  await $(find.byKey(const Key('proProfileBioField'))).enterText(text);
  await $.pumpAndTrySettle();
}

void main() {
  patrolSetUp(_signOutIfNeeded);
  patrolTearDown(_signOutIfNeeded);

  patrolTest('pro can open profile screen from bottom nav', ($) async {
    await _loginAsPro($);
    await _openProProfileScreen($);

    expect(find.text('My profile'), findsOneWidget);
    expect(find.byKey(const Key('proProfileBioField')), findsOneWidget);
    expect(find.byKey(const Key('proProfileRadiusField')), findsOneWidget);
  });

  patrolTest('save button is disabled when no changes have been made',
      ($) async {
    await _loginAsPro($);
    await _openProProfileScreen($);

    final button = $(find.byKey(const Key('proProfileSaveButton')))
        .first
        .evaluate()
        .first
        .widget as ElevatedButton;
    expect(button.onPressed, isNull);
  });

  patrolTest('editing bio enables the save button', ($) async {
    await _loginAsPro($);
    await _openProProfileScreen($);

    await _enterBioText($, 'Updated bio for testing');

    final button = $(find.byKey(const Key('proProfileSaveButton')))
        .first
        .evaluate()
        .first
        .widget as ElevatedButton;
    expect(button.onPressed, isNotNull);
  });

  patrolTest('editing radius enables the save button', ($) async {
    await _loginAsPro($);
    await _openProProfileScreen($);

    await $(find.byKey(const Key('proProfileRadiusField'))).tap();
    await $(find.byKey(const Key('proProfileRadiusField'))).enterText('');
    await $.pumpAndTrySettle();
    await $(find.byKey(const Key('proProfileRadiusField'))).enterText('30');
    await $.pumpAndTrySettle();

    final button = $(find.byKey(const Key('proProfileSaveButton')))
        .first
        .evaluate()
        .first
        .widget as ElevatedButton;
    expect(button.onPressed, isNotNull);
  });

  patrolTest('pro can update bio and see success snackbar', ($) async {
    await _loginAsPro($);
    await _openProProfileScreen($);

    await _enterBioText($, 'Experienced plumber with 10 years of service.');

    await $(find.byKey(const Key('proProfileSaveButton'))).scrollTo();
    await $(find.byKey(const Key('proProfileSaveButton'))).tap();
    await $(find.text('Profile updated'))
        .waitUntilVisible(timeout: const Duration(seconds: 15));
  });

  patrolTest('pro can update service radius and see success snackbar',
      ($) async {
    await _loginAsPro($);
    await _openProProfileScreen($);

    await $(find.byKey(const Key('proProfileRadiusField'))).tap();
    await $(find.byKey(const Key('proProfileRadiusField'))).enterText('');
    await $.pumpAndTrySettle();
    await $(find.byKey(const Key('proProfileRadiusField'))).enterText('20');
    await $.pumpAndTrySettle();

    await $(find.byKey(const Key('proProfileSaveButton'))).scrollTo();
    await $(find.byKey(const Key('proProfileSaveButton'))).tap();
    await $(find.text('Profile updated'))
        .waitUntilVisible(timeout: const Duration(seconds: 15));
  });

  patrolTest('save button is disabled again after successful save', ($) async {
    await _loginAsPro($);
    await _openProProfileScreen($);

    await _enterBioText($, 'Bio after save test.');

    await $(find.byKey(const Key('proProfileSaveButton'))).scrollTo();
    await $(find.byKey(const Key('proProfileSaveButton'))).tap();
    await $(find.text('Profile updated'))
        .waitUntilVisible(timeout: const Duration(seconds: 15));

    final button = $(find.byKey(const Key('proProfileSaveButton')))
        .first
        .evaluate()
        .first
        .widget as ElevatedButton;
    expect(button.onPressed, isNull);
  });

  patrolTest('pro can navigate back to home after editing profile', ($) async {
    await _loginAsPro($);
    await _openProProfileScreen($);

    await _enterBioText($, 'Back nav test bio.');

    await $(find.byKey(const Key('proProfileSaveButton'))).scrollTo();
    await $(find.byKey(const Key('proProfileSaveButton'))).tap();
    await $(find.text('Profile updated'))
        .waitUntilVisible(timeout: const Duration(seconds: 15));

    final backButton = find.byType(GestureDetector).first;
    await $(backButton).tap();
    await $(find.byType(HomeScreen))
        .waitUntilVisible(timeout: const Duration(seconds: 10));
  });
}
