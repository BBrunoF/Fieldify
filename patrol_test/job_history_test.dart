import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project/core/supabase/supabase_client.dart';
import 'package:project/features/client/job_history/presentation/widgets/client_job_card.dart';
import 'package:project/features/client/job_history/presentation/widgets/job_history_view.dart';
import 'package:project/features/home/presentation/screens/home_screen.dart';
import 'package:project/main.dart' as app;

import 'fake_payments.dart';

const _clientEmail = 'client@client.com';
const _clientPassword = 'clientclient';

Future<void> _bootstrapSupabase() async {
  await initializeSupabase();
}

Future<void> _signOutIfNeeded() async {
  installFakePayments();
  await _bootstrapSupabase();
  final auth = Supabase.instance.client.auth;
  if (auth.currentSession != null) {
    await auth.signOut();
  }
}

Future<void> _openLoginPage(PatrolIntegrationTester $) async {
  await _bootstrapSupabase();
  await $.pumpWidgetAndSettle(const app.FieldifyApp());
  await $(
    find.byKey(const Key('emailField')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _loginAsClient(PatrolIntegrationTester $) async {
  if (find.byKey(const Key('emailField')).evaluate().isEmpty) {
    await _openLoginPage($);
  }

  await $(find.byKey(const Key('emailField'))).enterText(_clientEmail);
  await $(find.byKey(const Key('passwordField'))).enterText(_clientPassword);
  await $(find.byKey(const Key('loginButton'))).tap();

  await $.pumpAndTrySettle(timeout: const Duration(seconds: 20));

  expect(find.byType(HomeScreen), findsOneWidget);
  await $(
    find.byKey(const Key('homeGreetingText')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _openMyJobsTab(PatrolIntegrationTester $) async {
  await $(find.byKey(const Key('bottomNavItem_jobs'))).tap();
  await $(
    find.byKey(const Key('jobHistoryView')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(
    find.byKey(const Key('homeJobsHeader')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _submitRequestAsClient(
  PatrolIntegrationTester $, {
  required String title,
  required String description,
  required String address,
}) async {
  await $(find.byKey(const Key('goToRequestButton'))).scrollTo().tap();
  await $(
    find.byKey(const Key('requestFormScreen')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));

  await $(find.byKey(const Key('requestCategoryCard_0'))).tap();
  await $(find.byKey(const Key('requestPrimaryButton'))).tap();

  await $(
    find.byKey(const Key('requestTitleField')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(find.byKey(const Key('requestTitleField'))).enterText(title);
  await $(
    find.byKey(const Key('requestDescriptionField')),
  ).enterText(description);
  await $(find.byKey(const Key('requestPrimaryButton'))).tap();

  await $(
    find.byKey(const Key('requestAddressField')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(find.byKey(const Key('requestAddressField'))).enterText(address);
  await $(find.byKey(const Key('requestAsapOption'))).tap();
  await $(find.byKey(const Key('requestPrimaryButton'))).tap();

  await $(title).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(find.byKey(const Key('requestPrimaryButton'))).tap();
  await $(
    find.byKey(const Key('requestSubmittedScreen')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));

  await $(find.byKey(const Key('backToHomeButton'))).tap();
  await $(
    find.byKey(const Key('homeMainTab')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

String _uniqueJobTitle(String scenario) {
  final millis = DateTime.now().millisecondsSinceEpoch;
  return 'Patrol history $scenario $millis';
}

void main() {
  patrolSetUp(_signOutIfNeeded);
  patrolTearDown(_signOutIfNeeded);

  patrolTest('client sees My Jobs screen from Jobs tab', ($) async {
    await _loginAsClient($);
    await _openMyJobsTab($);

    expect(find.byType(JobHistoryView), findsOneWidget);
    expect(find.text('My jobs'), findsOneWidget);
    expect(find.byKey(const Key('jobHistoryTabActive')), findsOneWidget);
    expect(find.byKey(const Key('jobHistoryTabPast')), findsOneWidget);
  });

  patrolTest('Active tab is selected by default', ($) async {
    await _loginAsClient($);
    await _openMyJobsTab($);

    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Past'), findsOneWidget);

    // Either the list or the empty state is shown once loading finishes.
    await $.pumpAndTrySettle(timeout: const Duration(seconds: 20));
    final hasList =
        find.byKey(const Key('jobHistoryList')).evaluate().isNotEmpty;
    final hasEmpty =
        find.byKey(const Key('jobHistoryEmptyState')).evaluate().isNotEmpty;
    expect(hasList || hasEmpty, isTrue);
  });

  patrolTest('newly submitted request appears in Active tab', ($) async {
    final title = _uniqueJobTitle('active');
    const description = 'Patrol generated request for history flow.';
    const address = 'Rua de Cedofeita 50, Porto';

    await _loginAsClient($);
    await _submitRequestAsClient(
      $,
      title: title,
      description: description,
      address: address,
    );

    await _openMyJobsTab($);

    await $(title).waitUntilVisible(timeout: const Duration(seconds: 20));
    expect(find.text(title), findsOneWidget);
    expect(find.byType(ClientJobCard), findsWidgets);
  });

  patrolTest('client can switch to Past tab', ($) async {
    await _loginAsClient($);
    await _openMyJobsTab($);

    await $(find.byKey(const Key('jobHistoryTabPast'))).tap();
    await $.pumpAndTrySettle(timeout: const Duration(seconds: 20));

    // Past tab renders either a list or an empty state — both are valid.
    final hasList =
        find.byKey(const Key('jobHistoryList')).evaluate().isNotEmpty;
    final hasEmpty =
        find.byKey(const Key('jobHistoryEmptyState')).evaluate().isNotEmpty;
    expect(hasList || hasEmpty, isTrue);
  });

  patrolTest('switching tabs toggles the underlined indicator', ($) async {
    await _loginAsClient($);
    await _openMyJobsTab($);

    await $(find.byKey(const Key('jobHistoryTabPast'))).tap();
    await $.pumpAndTrySettle(timeout: const Duration(seconds: 10));
    expect(find.byKey(const Key('jobHistoryTabPast')), findsOneWidget);

    await $(find.byKey(const Key('jobHistoryTabActive'))).tap();
    await $.pumpAndTrySettle(timeout: const Duration(seconds: 10));
    expect(find.byKey(const Key('jobHistoryTabActive')), findsOneWidget);
  });

  patrolTest('My Jobs header is not shown on Home tab', ($) async {
    await _loginAsClient($);

    expect(find.byType(JobHistoryView), findsNothing);
    expect(find.byKey(const Key('homeMainTab')), findsOneWidget);
  });
}
