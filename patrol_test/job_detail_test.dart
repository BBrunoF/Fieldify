import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project/core/supabase/supabase_client.dart';
import 'package:project/features/home/presentation/screens/home_screen.dart';
import 'package:project/features/shared/job_detail/presentation/screens/job_detail_screen.dart';
import 'package:project/main.dart' as app;

import 'fake_payments.dart';

const _clientEmail = 'client@client.com';
const _clientPassword = 'clientclient';

Future<void> _signOutIfNeeded() async {
  installFakePayments();
  await initializeSupabase();
  final auth = Supabase.instance.client.auth;
  if (auth.currentSession != null) {
    await auth.signOut();
  }
}

Future<void> _loginAsClient(PatrolIntegrationTester $) async {
  await initializeSupabase();
  await $.tester.pumpWidget(const app.FieldifyApp());
  await $(find.byKey(const Key('emailField')))
      .waitUntilVisible(timeout: const Duration(seconds: 20));

  await $(find.byKey(const Key('emailField'))).enterText(_clientEmail);
  await $(find.byKey(const Key('passwordField'))).enterText(_clientPassword);
  await $(find.byKey(const Key('loginButton'))).tap();

  await $.pumpAndTrySettle(timeout: const Duration(seconds: 20));

  expect(find.byType(HomeScreen), findsOneWidget);
  await $(find.byKey(const Key('homeGreetingText')))
      .waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _openMyJobsTab(PatrolIntegrationTester $) async {
  await $(find.byKey(const Key('bottomNavItem_jobs'))).tap();
  await $(find.byKey(const Key('jobHistoryView')))
      .waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _submitRequestAsClient(
  PatrolIntegrationTester $, {
  required String title,
  required String description,
  required String address,
}) async {
  await $(find.byKey(const Key('goToRequestButton'))).scrollTo().tap();
  await $(find.byKey(const Key('requestFormScreen')))
      .waitUntilVisible(timeout: const Duration(seconds: 20));

  await $(find.byKey(const Key('requestCategoryCard_0')))
      .waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(find.byKey(const Key('requestCategoryCard_0'))).tap();
  await $(find.byKey(const Key('requestPrimaryButton'))).tap();

  await $(find.byKey(const Key('requestTitleField')))
      .waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(find.byKey(const Key('requestTitleField'))).enterText(title);
  await $(find.byKey(const Key('requestDescriptionField'))).enterText(description);
  await $(find.byKey(const Key('requestPrimaryButton'))).tap();

  await $(find.byKey(const Key('requestAddressField')))
      .waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(find.byKey(const Key('requestAddressField'))).enterText(address);
  await $(find.byKey(const Key('requestAsapOption'))).tap();
  await $(find.byKey(const Key('requestPrimaryButton'))).tap();

  await $(title).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(find.byKey(const Key('requestPrimaryButton'))).tap();
  await $(find.byKey(const Key('requestSubmittedScreen')))
      .waitUntilVisible(timeout: const Duration(seconds: 20));

  await $(find.byKey(const Key('backToHomeButton'))).tap();
  await $(find.byKey(const Key('homeMainTab')))
      .waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _openFirstJobDetail(PatrolIntegrationTester $, String title) async {
  await $(title).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(find.textContaining('Track').first).tap();
  await $(find.byKey(const Key('jobDetailScreen')))
      .waitUntilVisible(timeout: const Duration(seconds: 20));
  await $.pumpAndTrySettle(timeout: const Duration(seconds: 10));
}

String _uniqueJobTitle(String scenario) {
  final millis = DateTime.now().millisecondsSinceEpoch;
  return 'Patrol detail $scenario $millis';
}

void main() {
  patrolSetUp(_signOutIfNeeded);
  patrolTearDown(_signOutIfNeeded);

  patrolTest('client opens job detail from the Jobs tab', ($) async {
    final title = _uniqueJobTitle('open');
    await _loginAsClient($);
    await _submitRequestAsClient(
      $,
      title: title,
      description: 'Patrol generated request for detail flow.',
      address: 'Rua de Cedofeita 50, Porto',
    );

    await _openMyJobsTab($);
    await _openFirstJobDetail($, title);

    expect(find.byType(JobDetailScreen), findsOneWidget);
    expect(find.text(title), findsWidgets);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Cancel request'), findsOneWidget);
  });

  patrolTest('pending detail shows request details and address', ($) async {
    final title = _uniqueJobTitle('details');
    await _loginAsClient($);
    await _submitRequestAsClient(
      $,
      title: title,
      description: 'Patrol generated request for detail flow.',
      address: 'Rua de Cedofeita 50, Porto',
    );

    await _openMyJobsTab($);
    await _openFirstJobDetail($, title);

    expect(find.textContaining('Porto'), findsWidgets);
    expect(find.text('Pending'), findsOneWidget);
  });

  patrolTest('client cancels a pending job from the detail screen', ($) async {
    final title = _uniqueJobTitle('cancel');
    await _loginAsClient($);
    await _submitRequestAsClient(
      $,
      title: title,
      description: 'Patrol generated request for detail cancel.',
      address: 'Rua de Cedofeita 50, Porto',
    );

    await _openMyJobsTab($);
    await _openFirstJobDetail($, title);

    await $(find.text('Cancel request')).tap();
    await $.pumpAndTrySettle(timeout: const Duration(seconds: 20));

    expect(find.text('Cancelled'), findsWidgets);
    expect(find.text('Submit a new request'), findsOneWidget);
  });

  patrolTest('back arrow returns from detail to My Jobs', ($) async {
    final title = _uniqueJobTitle('back');
    await _loginAsClient($);
    await _submitRequestAsClient(
      $,
      title: title,
      description: 'Patrol generated request for back-nav flow.',
      address: 'Rua de Cedofeita 50, Porto',
    );

    await _openMyJobsTab($);
    await _openFirstJobDetail($, title);

    await $(find.byKey(const Key('jobDetailBackButton'))).tap();
    await $.pumpAndTrySettle(timeout: const Duration(seconds: 10));

    expect(find.byType(JobDetailScreen), findsNothing);
    expect(find.byKey(const Key('jobHistoryView')), findsOneWidget);
  });
}
