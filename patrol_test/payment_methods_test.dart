import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project/core/supabase/supabase_client.dart';
import 'package:project/features/home/presentation/screens/home_screen.dart';
import 'package:project/features/client/profile/presentation/screens/profile_screen.dart';
import 'package:project/features/shared/payments/presentation/screens/payment_methods_screen.dart';
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
  await $.pumpAndTrySettle(timeout: const Duration(seconds: 10));
}

Future<void> _openPaymentMethods(PatrolIntegrationTester $) async {
  await $(find.byKey(const Key('profilePaymentMethodsButton'))).scrollTo().tap();
  await $(find.byType(PaymentMethodsScreen)).waitUntilVisible(
    timeout: const Duration(seconds: 20),
  );
  await $.pumpAndTrySettle(timeout: const Duration(seconds: 10));
}

void main() {
  patrolSetUp(_signOutIfNeeded);
  patrolTearDown(_signOutIfNeeded);

  patrolTest('client can open payment methods from profile', ($) async {
    await _loginAsClient($);
    await _openProfileScreen($);
    await _openPaymentMethods($);

    expect(find.byKey(const Key('paymentMethodsScreen')), findsOneWidget);
    expect(find.text('Payment methods'), findsWidgets);
    // The add-card action is always available.
    expect(
      find.byKey(const Key('paymentMethodsAddCardButton')),
      findsOneWidget,
    );
  });

  patrolTest('payment methods screen lists saved cards or an empty state',
      ($) async {
    await _loginAsClient($);
    await _openProfileScreen($);
    await _openPaymentMethods($);

    // Either the client has saved cards (tiles render the masked PAN) or the
    // empty-state copy is shown — both are valid, neither should crash.
    final hasEmptyState =
        find.textContaining('No cards saved yet').evaluate().isNotEmpty;
    final hasCard = find.textContaining('••••').evaluate().isNotEmpty;

    expect(hasEmptyState || hasCard, isTrue);
  });
}
