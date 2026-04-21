import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project/core/supabase/supabase_client.dart';
import 'package:project/features/home/presentation/screens/home_screen.dart';
import 'package:project/features/pro/incoming_jobs/presentation/widgets/incoming_job_card.dart';
import 'package:project/features/pro/incoming_jobs/presentation/widgets/incoming_jobs_view.dart';
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

Future<void> _openRequestFlow(PatrolIntegrationTester $) async {
  await $(find.byKey(const Key('goToRequestButton'))).scrollTo().tap();
  await $(
    find.byKey(const Key('requestFormScreen')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _submitRequestAsClient(
  PatrolIntegrationTester $, {
  required String title,
  required String description,
  required String address,
}) async {
  await _openRequestFlow($);

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
  expect(find.text(address), findsOneWidget);

  await $(find.byKey(const Key('requestPrimaryButton'))).tap();
  await $(
    find.byKey(const Key('requestSubmittedScreen')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(
    find.byKey(const Key('requestSubmittedTitle')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _returnToHomeAfterSubmission(PatrolIntegrationTester $) async {
  await $(find.byKey(const Key('backToHomeButton'))).tap();
  await $(
    find.byKey(const Key('homeMainTab')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _openIncomingJobsTab(PatrolIntegrationTester $) async {
  await $(find.byKey(const Key('bottomNavItem_jobs'))).tap();
  await $(
    find.byKey(const Key('incomingJobsView')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(
    find.byKey(const Key('homeJobsHeader')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _setShowRejected(PatrolIntegrationTester $, bool value) async {
  final checkboxFinder = find.byKey(
    const Key('incomingJobsShowRejectedCheckbox'),
  );

  await $(
    checkboxFinder,
  ).waitUntilVisible(timeout: const Duration(seconds: 20));

  final currentValue = $.tester.widget<CheckboxListTile>(checkboxFinder).value;
  if (currentValue != value) {
    await $(checkboxFinder).tap();
    await $.pumpAndTrySettle(timeout: const Duration(seconds: 20));
  }

  expect($.tester.widget<CheckboxListTile>(checkboxFinder).value, value);
}

Finder _requestCardFinder(String title) {
  return find.ancestor(
    of: find.text(title),
    matching: find.byType(IncomingJobCard),
  );
}

Finder _requestActionFinder({required String title, required String label}) {
  return find.descendant(
    of: _requestCardFinder(title),
    matching: find.text(label),
  );
}

Future<void> _waitForRequestInJobs(
  PatrolIntegrationTester $,
  String title,
) async {
  await $(title).waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _waitForRequestToDisappearFromJobs(
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

  final snackBarTextFinder = find.descendant(
    of: find.byType(SnackBar),
    matching: find.byType(Text),
  );
  final snackBarTexts = $.tester
      .widgetList<Text>(snackBarTextFinder)
      .map((widget) => widget.data)
      .whereType<String>()
      .join(' | ');

  fail(
    snackBarTexts.isEmpty
        ? 'Request "$title" was still visible after the action completed.'
        : 'Request "$title" was still visible after the action completed. '
              'SnackBar: $snackBarTexts',
  );
}

String _uniqueRequestTitle(String scenario) {
  final millis = DateTime.now().millisecondsSinceEpoch;
  return 'Patrol $scenario $millis';
}

void main() {
  patrolSetUp(_signOutIfNeeded);
  patrolTearDown(_signOutIfNeeded);

  patrolTest('client can submit a new request', ($) async {
    final title = _uniqueRequestTitle('client-request');
    const description = 'Patrol generated request for client submission flow.';
    const address = 'Avenida dos Aliados 100, Porto';

    await _loginAsClient($);
    await _submitRequestAsClient(
      $,
      title: title,
      description: description,
      address: address,
    );

    await _returnToHomeAfterSubmission($);
    expect(find.byKey(const Key('bottomNavItem_jobs')), findsOneWidget);
  });

  patrolTest('professional can accept a client request', ($) async {
    final title = _uniqueRequestTitle('accept');
    const description = 'Patrol generated request for accept flow.';
    const address = 'Rua de Santa Catarina 200, Porto';

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
    await _waitForRequestInJobs($, title);

    expect(find.byType(IncomingJobsView), findsOneWidget);
    expect(find.text(title), findsOneWidget);

    await $(_requestActionFinder(title: title, label: 'Accept')).tap();
    await _waitForRequestToDisappearFromJobs($, title);
  });

  patrolTest('professional can reject a client request', ($) async {
    final title = _uniqueRequestTitle('reject');
    const description = 'Patrol generated request for reject flow.';
    const address = 'Rua das Flores 80, Porto';

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
    await _waitForRequestInJobs($, title);

    await $(_requestActionFinder(title: title, label: 'Reject')).tap();
    await _waitForRequestToDisappearFromJobs($, title);

    await _setShowRejected($, true);
    await _waitForRequestInJobs($, title);
    await $(
      _requestActionFinder(title: title, label: 'Reject again'),
    ).waitUntilVisible(timeout: const Duration(seconds: 20));
    expect(
      find.descendant(
        of: _requestCardFinder(title),
        matching: find.text('REJECTED'),
      ),
      findsOneWidget,
    );
  });
}
