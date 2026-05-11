import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project/core/supabase/supabase_client.dart';
import 'package:project/features/home/presentation/screens/home_screen.dart';
import 'package:project/main.dart' as app;

const _validEmail = 'client@client.com';
const _validPassword = 'clientclient';

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

Future<void> _openLoginPage(PatrolIntegrationTester $) async {
  await _bootstrapSupabase();
  await $.pumpWidgetAndSettle(const app.FieldifyApp());
}

void main() {
  patrolSetUp(_signOutIfNeeded);
  patrolTearDown(_signOutIfNeeded);

  patrolTest('open login page', ($) async {
    await _openLoginPage($);

    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
    expect(find.byKey(const Key('loginButton')), findsOneWidget);
  });

  patrolTest('login successful', ($) async {
    await _openLoginPage($);

    await $(find.byKey(const Key('emailField'))).enterText(_validEmail);
    await $(find.byKey(const Key('passwordField'))).enterText(_validPassword);
    await $(find.byKey(const Key('loginButton'))).tap();

    await $.pumpAndTrySettle(timeout: const Duration(seconds: 20));

    expect(find.byType(HomeScreen), findsOneWidget);
    await $(find.byKey(const Key('homeGreetingText')))
        .waitUntilVisible(timeout: const Duration(seconds: 20));
  });

  patrolTest('invalid login', ($) async {
    await _openLoginPage($);

    await $(find.byKey(const Key('emailField'))).enterText(_validEmail);
    await $(find.byKey(const Key('passwordField'))).enterText('wrongpassword');
    await $(find.byKey(const Key('loginButton'))).tap();

    await $.pumpAndTrySettle(timeout: const Duration(seconds: 20));

    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byKey(const Key('loginButton')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.toLowerCase().contains('invalid') ?? false),
      ),
      findsWidgets,
    );
  });
}
