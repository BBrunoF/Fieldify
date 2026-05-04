import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project/core/supabase/supabase_client.dart';
import 'package:project/features/home/presentation/screens/home_screen.dart';
import 'package:project/features/pro/accepted_jobs/presentation/widgets/accepted_job_card.dart';
import 'package:project/features/pro/accepted_jobs/presentation/widgets/accepted_jobs_view.dart';
import 'package:project/features/pro/incoming_jobs/presentation/widgets/incoming_job_card.dart';
import 'package:project/features/pro/incoming_jobs/presentation/widgets/incoming_jobs_view.dart';
import 'package:project/features/pro/jobs/presentation/widgets/pro_jobs_view.dart';
import 'package:project/main.dart' as app;

const _clientEmail = 'client@client.com';
const _clientPassword = 'clientclient';
const _professionalEmail = 'test@test.com';
const _professionalPassword = 'testtest';

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
  await $(
    find.byKey(const Key('emailField')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _login(
  PatrolIntegrationTester $, {
  required String email,
  required String password,
}) async {
  if (find.byKey(const Key('emailField')).evaluate().isEmpty) {
    await _openLoginPage($);
  } else {
    await $(
      find.byKey(const Key('emailField')),
    ).waitUntilVisible(timeout: const Duration(seconds: 20));
  }

  await $(find.byKey(const Key('emailField'))).enterText(email);
  await $(find.byKey(const Key('passwordField'))).enterText(password);
  await $(find.byKey(const Key('loginButton'))).tap();

  await $.pumpAndTrySettle(timeout: const Duration(seconds: 20));

  expect(find.byType(HomeScreen), findsOneWidget);
  await $(
    find.byKey(const Key('homeGreetingText')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(
    find.byKey(const Key('bottomNavItem_jobs')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _loginAsClient(PatrolIntegrationTester $) async {
  await _login($, email: _clientEmail, password: _clientPassword);
}

Future<void> _loginAsProfessional(PatrolIntegrationTester $) async {
  await _login($, email: _professionalEmail, password: _professionalPassword);
}

Future<void> _logoutToLogin(PatrolIntegrationTester $) async {
  if (find.byKey(const Key('bottomNavItem_home')).evaluate().isNotEmpty) {
    await $(find.byKey(const Key('bottomNavItem_home'))).tap();
  }

  await $(
    find.byKey(const Key('homeLogoutButton')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(find.byKey(const Key('homeLogoutButton'))).tap();

  await $(
    find.byKey(const Key('emailField')),
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

  await $(
    find.byKey(const Key('requestCategoryCard_0')),
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
}

Future<void> _returnToHomeAfterSubmission(PatrolIntegrationTester $) async {
  await $(find.byKey(const Key('backToHomeButton'))).tap();
  await $(
    find.byKey(const Key('homeMainTab')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _openProJobsTab(PatrolIntegrationTester $) async {
  await $(find.byKey(const Key('bottomNavItem_jobs'))).tap();
  await $(
    find.byKey(const Key('homeJobsHeader')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(
    find.byKey(const Key('proJobsView')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _openIncomingJobsTab(PatrolIntegrationTester $) async {
  await _openProJobsTab($);
  await $(
    find.byKey(const Key('proJobsTabIncoming')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(
    find.byKey(const Key('incomingJobsView')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _openAcceptedJobsTab(PatrolIntegrationTester $) async {
  await $(find.byKey(const Key('proJobsTabAccepted'))).tap();
  await $(
    find.byType(AcceptedJobsView),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
  await _waitForAcceptedJobsBody($);
}

Future<void> _waitForAcceptedJobsBody(PatrolIntegrationTester $) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));

  while (DateTime.now().isBefore(deadline)) {
    await $.pump(const Duration(milliseconds: 250));
    final hasList = find
        .byKey(const Key('acceptedJobsList'))
        .evaluate()
        .isNotEmpty;
    final hasEmpty = find
        .byKey(const Key('acceptedJobsEmptyState'))
        .evaluate()
        .isNotEmpty;
    if (hasList || hasEmpty) {
      return;
    }
  }

  fail('Accepted jobs did not finish loading.');
}

Finder _incomingCardFinder(String title) {
  return find.ancestor(
    of: find.text(title),
    matching: find.byType(IncomingJobCard),
  );
}

Finder _incomingActionFinder({required String title, required String label}) {
  return find.descendant(
    of: _incomingCardFinder(title),
    matching: find.text(label),
  );
}

Finder _acceptedCardFinder(String title) {
  return find.ancestor(
    of: find.text(title),
    matching: find.byType(AcceptedJobCard),
  );
}

Finder _acceptedActionFinder({required String title, required String label}) {
  return find.descendant(
    of: _acceptedCardFinder(title),
    matching: find.text(label),
  );
}

Future<void> _waitForIncomingRequest(
  PatrolIntegrationTester $,
  String title,
) async {
  await $(title).waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _acceptIncomingRequest(
  PatrolIntegrationTester $,
  String title,
) async {
  await _waitForIncomingRequest($, title);
  await $(_incomingActionFinder(title: title, label: 'Accept')).tap();
  await _waitForIncomingRequestToDisappear($, title);
}

Future<void> _waitForIncomingRequestToDisappear(
  PatrolIntegrationTester $,
  String title,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));

  while (DateTime.now().isBefore(deadline)) {
    await $.pump(const Duration(milliseconds: 250));
    if (find.text(title).evaluate().isEmpty) {
      return;
    }
  }

  fail('Incoming request "$title" was still visible after accepting it.');
}

Future<void> _waitForAcceptedJob(
  PatrolIntegrationTester $,
  String title,
) async {
  await $(title).scrollTo(
    view: find.byKey(const Key('acceptedJobsList')),
    step: 320,
    maxScrolls: 80,
  );
  await $(title).waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _waitForAcceptedJobToDisappear(
  PatrolIntegrationTester $,
  String title,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));

  while (DateTime.now().isBefore(deadline)) {
    await $.pump(const Duration(milliseconds: 250));
    if (find.text(title).evaluate().isEmpty) {
      return;
    }
  }

  fail('Accepted job "$title" was still visible after cancelling it.');
}

String _uniqueRequestTitle(String scenario) {
  final millis = DateTime.now().millisecondsSinceEpoch;
  return 'Patrol pro jobs $scenario $millis';
}

void main() {
  patrolSetUp(_signOutIfNeeded);
  patrolTearDown(_signOutIfNeeded);

  patrolTest('professional can switch between Incoming and Accepted tabs', (
    $,
  ) async {
    await _loginAsProfessional($);
    await _openIncomingJobsTab($);

    expect(find.byType(ProJobsView), findsOneWidget);
    expect(find.byType(IncomingJobsView), findsOneWidget);
    expect(find.byKey(const Key('proJobsTabIncoming')), findsOneWidget);
    expect(find.byKey(const Key('proJobsTabAccepted')), findsOneWidget);

    await _openAcceptedJobsTab($);

    expect(find.byType(AcceptedJobsView), findsOneWidget);
    final hasList = find
        .byKey(const Key('acceptedJobsList'))
        .evaluate()
        .isNotEmpty;
    final hasEmpty = find
        .byKey(const Key('acceptedJobsEmptyState'))
        .evaluate()
        .isNotEmpty;
    expect(hasList || hasEmpty, isTrue);
  });

  patrolTest('accepted client requests appear in the Accepted tab in order', (
    $,
  ) async {
    final firstTitle = _uniqueRequestTitle('accepted-first');
    final secondTitle = _uniqueRequestTitle('accepted-second');
    const description = 'Patrol generated request for pro accepted jobs.';
    const address = 'Rua de Santa Catarina 200, Porto';

    await _loginAsClient($);
    await _submitRequestAsClient(
      $,
      title: firstTitle,
      description: description,
      address: address,
    );
    await _returnToHomeAfterSubmission($);
    await _submitRequestAsClient(
      $,
      title: secondTitle,
      description: description,
      address: address,
    );
    await _returnToHomeAfterSubmission($);
    await _logoutToLogin($);

    await _loginAsProfessional($);
    await _openIncomingJobsTab($);
    await _acceptIncomingRequest($, firstTitle);
    await _acceptIncomingRequest($, secondTitle);

    await _openAcceptedJobsTab($);
    await _waitForAcceptedJob($, secondTitle);

    expect(find.byType(AcceptedJobCard), findsWidgets);
    expect(find.text(firstTitle), findsOneWidget);
    expect(find.text(secondTitle), findsOneWidget);
    expect(find.text('Accepted'), findsWidgets);
    expect(find.text('Accept'), findsNothing);
    expect(find.text('Reject'), findsNothing);

    final firstY = $.tester.getCenter(find.text(firstTitle)).dy;
    final secondY = $.tester.getCenter(find.text(secondTitle)).dy;
    expect(firstY, lessThan(secondY));
  });

  patrolTest('professional cancellation returns an accepted job to Incoming', (
    $,
  ) async {
    final title = _uniqueRequestTitle('cancel-to-incoming');
    const description = 'Patrol generated request for pro cancellation.';
    const address = 'Rua de Santa Catarina 220, Porto';

    await _loginAsClient($);
    await _submitRequestAsClient(
      $,
      title: title,
      description: description,
      address: address,
    );
    await _returnToHomeAfterSubmission($);
    await _logoutToLogin($);

    await _loginAsProfessional($);
    await _openIncomingJobsTab($);
    await _acceptIncomingRequest($, title);

    await _openAcceptedJobsTab($);
    await _waitForAcceptedJob($, title);
    await $(_acceptedActionFinder(title: title, label: 'Cancel job')).tap();
    await _waitForAcceptedJobToDisappear($, title);

    await $(find.byKey(const Key('proJobsTabIncoming'))).tap();
    await $(
      find.byKey(const Key('incomingJobsView')),
    ).waitUntilVisible(timeout: const Duration(seconds: 20));
    await _waitForIncomingRequest($, title);

    expect(find.byType(IncomingJobCard), findsWidgets);
    expect(
      _incomingActionFinder(title: title, label: 'Accept'),
      findsOneWidget,
    );
  });
}
