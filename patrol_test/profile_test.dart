import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project/core/supabase/supabase_client.dart';
import 'package:project/features/home/presentation/screens/home_screen.dart';
import 'package:project/features/client/profile/presentation/screens/profile_screen.dart';
import 'package:project/main.dart' as app;

const _clientEmail = 'client@client.com';
const _clientPassword = 'clientclient';

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

Future<void> _loginAsClient(PatrolIntegrationTester $) async {
  await _bootstrapSupabase();
  await $.pumpWidgetAndSettle(const app.FieldifyApp());

  await $(
    find.byKey(const Key('emailField')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));

  await $(find.byKey(const Key('emailField'))).enterText(_clientEmail);
  await $(find.byKey(const Key('passwordField'))).enterText(_clientPassword);
  await $(find.byKey(const Key('loginButton'))).tap();

  await $.pumpAndTrySettle(timeout: const Duration(seconds: 20));

  expect(find.byType(HomeScreen), findsOneWidget);
  await $(
    find.byKey(const Key('homeGreetingText')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _openProfileScreen(PatrolIntegrationTester $) async {
  await $(find.byKey(const Key('bottomNavItem_profile'))).tap();
  await $(find.byType(ProfileScreen)).waitUntilVisible(
    timeout: const Duration(seconds: 20),
  );
}

void main() {
  patrolSetUp(_signOutIfNeeded);
  patrolTearDown(_signOutIfNeeded);

  patrolTest('client can open profile screen from bottom nav', ($) async {
    await _loginAsClient($);
    await _openProfileScreen($);

    expect(find.text('My profile'), findsOneWidget);
    expect(find.byKey(const Key('profileFirstNameField')), findsOneWidget);
    expect(find.byKey(const Key('profileLastNameField')), findsOneWidget);
    expect(find.byKey(const Key('profilePhoneField')), findsOneWidget);
  });

  patrolTest('profile fields are pre-filled with current user data',
      ($) async {
    await _loginAsClient($);
    await _openProfileScreen($);

    final firstName = $(find.byKey(const Key('profileFirstNameField')))
        .first
        .evaluate()
        .first
        .widget;
    expect(firstName, isA<TextFormField>());
  });

  patrolTest('save button is disabled when no changes have been made',
      ($) async {
    await _loginAsClient($);
    await _openProfileScreen($);

    final button = $(find.byKey(const Key('profileSaveButton')))
        .first
        .evaluate()
        .first
        .widget as ElevatedButton;
    expect(button.onPressed, isNull);
  });

  patrolTest('editing a field enables the save button', ($) async {
    await _loginAsClient($);
    await _openProfileScreen($);

    await $(find.byKey(const Key('profilePhoneField'))).enterText('912999888');
    await $.pumpAndTrySettle();

    final button = $(find.byKey(const Key('profileSaveButton')))
        .first
        .evaluate()
        .first
        .widget as ElevatedButton;
    expect(button.onPressed, isNotNull);
  });

  patrolTest('client can update phone number and see success snackbar',
      ($) async {
    await _loginAsClient($);
    await _openProfileScreen($);

    const newPhone = '912888777';
    await $(find.byKey(const Key('profilePhoneField'))).tap();
    await $(find.byKey(const Key('profilePhoneField'))).enterText(newPhone);
    await $.pumpAndTrySettle();

    await $(find.byKey(const Key('profileSaveButton'))).tap();
    await $.pumpAndTrySettle(timeout: const Duration(seconds: 15));

    expect(find.text('Profile updated'), findsOneWidget);
  });

  patrolTest('client can add a new address', ($) async {
    await _loginAsClient($);
    await _openProfileScreen($);

    await $(find.byKey(const Key('profileAddAddressButton'))).tap();
    await $.pumpAndTrySettle();

    await $(find.byType(TextFormField).last).enterText(
      'Rua de Santa Catarina 10, Porto',
    );
    await $.pumpAndTrySettle();

    await $(find.text('Add')).tap();
    await $.pumpAndTrySettle();

    expect(find.text('Rua de Santa Catarina 10, Porto'), findsOneWidget);
  });

  patrolTest(
      'updated name is reflected on home screen after profile save and back',
      ($) async {
    await _loginAsClient($);
    await _openProfileScreen($);

    await $(find.byKey(const Key('profileFirstNameField'))).tap();
    await $(find.byKey(const Key('profileFirstNameField')))
        .enterText('Patrol');
    await $(find.byKey(const Key('profileLastNameField'))).tap();
    await $(find.byKey(const Key('profileLastNameField'))).enterText('Test');
    await $.pumpAndTrySettle();

    await $(find.byKey(const Key('profileSaveButton'))).tap();
    await $.pumpAndTrySettle(timeout: const Duration(seconds: 15));

    expect(find.text('Profile updated'), findsOneWidget);

    final backButton = find.byType(GestureDetector).first;
    await $(backButton).tap();
    await $.pumpAndTrySettle(timeout: const Duration(seconds: 15));

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
