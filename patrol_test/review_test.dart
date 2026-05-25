import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project/core/supabase/supabase_client.dart';
import 'package:project/features/home/presentation/screens/home_screen.dart';
import 'package:project/features/pro/profile/presentation/screens/pro_profile_screen.dart';
import 'package:project/features/shared/job_detail/presentation/screens/job_detail_screen.dart';
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
}

Future<void> _loginAsClient(PatrolIntegrationTester $) =>
    _login($, email: _clientEmail, password: _clientPassword);

Future<void> _loginAsProfessional(PatrolIntegrationTester $) =>
    _login($, email: _professionalEmail, password: _professionalPassword);

Future<void> _logoutToLogin(PatrolIntegrationTester $) async {
  // If we're inside a job detail screen, pop back to the host scaffold first.
  if (find.byKey(const Key('jobDetailBackButton')).evaluate().isNotEmpty) {
    await $(find.byKey(const Key('jobDetailBackButton'))).tap();
    await $.pumpAndTrySettle(timeout: const Duration(seconds: 10));
  }

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

  await $(find.byKey(const Key('backToHomeButton'))).tap();
  await $(
    find.byKey(const Key('homeMainTab')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _openIncomingJobsTab(PatrolIntegrationTester $) async {
  await $(find.byKey(const Key('bottomNavItem_jobs'))).tap();
  await $(
    find.byKey(const Key('proJobsTabIncoming')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _openAcceptedJobsTab(PatrolIntegrationTester $) async {
  await $(find.byKey(const Key('proJobsTabAccepted'))).tap();
  await $.pumpAndTrySettle(timeout: const Duration(seconds: 10));
}

Future<void> _acceptIncomingRequest(
  PatrolIntegrationTester $,
  String title,
) async {
  await $(title).waitUntilVisible(timeout: const Duration(seconds: 30));
  final acceptButton = find.descendant(
    of: find.ancestor(of: find.text(title), matching: find.byType(Card)),
    matching: find.text('Accept'),
  );
  if (acceptButton.evaluate().isNotEmpty) {
    await $(acceptButton).tap();
  } else {
    await $(find.text('Accept').first).tap();
  }
  // Accept is fire-and-forget (the tap handler's Future is not awaited by the
  // framework), so pumpAndTrySettle alone returns before the Supabase update
  // commits. Wait until the job leaves the Incoming list — the controller only
  // removes it after acceptJob() completes — so the Accepted tab's first fetch
  // is guaranteed to see the accepted row.
  await _waitUntilGone($, find.text(title));
}

/// Polls until [finder] matches no widgets, pumping between checks. Patrol
/// finders only ship waitUntilVisible, so this covers the "wait until gone"
/// case needed after an async mutation removes an item from a list.
Future<void> _waitUntilGone(
  PatrolIntegrationTester $,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await $.pumpAndTrySettle(timeout: const Duration(seconds: 2));
    if (finder.evaluate().isEmpty) return;
  }
  throw TimeoutException(
    'Widget still present after ${timeout.inSeconds}s: $finder',
  );
}

Future<void> _progressJobToCompleted(
  PatrolIntegrationTester $,
  String title,
) async {
  await _openAcceptedJobsTab($);
  // fetchAcceptedJobs orders by accepted_at descending, so the job just
  // accepted is at the top of the list and visible without scrolling.
  await $(title).waitUntilVisible(timeout: const Duration(seconds: 30));
  await $(find.text(title)).tap();

  await $(
    find.byKey(const Key('jobDetailScreen')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));

  await $(find.text('Start heading over')).tap();
  await $.pumpAndTrySettle(timeout: const Duration(seconds: 10));

  await $(
    find.text("I've arrived — start job"),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(find.text("I've arrived — start job")).tap();
  await $.pumpAndTrySettle(timeout: const Duration(seconds: 10));

  await $(
    find.text('Mark job complete'),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(find.text('Mark job complete')).tap();
  await $.pumpAndTrySettle(timeout: const Duration(seconds: 10));

  await $(
    find.text('Completed'),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));

  // Pop back out of the detail screen so home/profile nav is reachable again.
  await $(find.byKey(const Key('jobDetailBackButton'))).tap();
  await $.pumpAndTrySettle(timeout: const Duration(seconds: 10));
}

Future<void> _openCompletedJobAsClient(
  PatrolIntegrationTester $,
  String title,
) async {
  await $(find.byKey(const Key('bottomNavItem_jobs'))).tap();
  await $(
    find.byKey(const Key('jobHistoryView')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(find.byKey(const Key('jobHistoryTabPast'))).tap();
  await $.pumpAndTrySettle(timeout: const Duration(seconds: 10));

  await $(title).waitUntilVisible(timeout: const Duration(seconds: 20));
  // Completed jobs render a "Details" button on the card; tap that to open
  // the detail screen. Tapping the title alone does not navigate.
  final detailsButton = find.descendant(
    of: find.ancestor(of: find.text(title), matching: find.byType(Card)),
    matching: find.text('Details'),
  );
  if (detailsButton.evaluate().isNotEmpty) {
    await $(detailsButton).tap();
  } else {
    await $(find.text('Details').first).tap();
  }
  await $(
    find.byKey(const Key('jobDetailScreen')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

/// Creates a completed job end-to-end: client submits, pro completes the
/// full status flow, then signs the client back in ready to review.
Future<void> _setupCompletedJob(
  PatrolIntegrationTester $, {
  required String title,
}) async {
  const description = 'Patrol generated request for review flow.';
  const address = 'Rua de Cedofeita 50, Porto';

  await _loginAsClient($);
  await _submitRequestAsClient(
    $,
    title: title,
    description: description,
    address: address,
  );
  await _logoutToLogin($);

  await _loginAsProfessional($);
  await _openIncomingJobsTab($);
  await _acceptIncomingRequest($, title);
  await _progressJobToCompleted($, title);
  await _logoutToLogin($);

  await _loginAsClient($);
}

String _uniqueTitle(String scenario) {
  final millis = DateTime.now().millisecondsSinceEpoch;
  return 'Patrol review $scenario $millis';
}

void main() {
  patrolSetUp(_signOutIfNeeded);
  patrolTearDown(_signOutIfNeeded);

  // UAT #1 — "Given a job is marked Done, when I open the app, I'm prompted
  // to rate the provider."
  patrolTest(
    'completed job shows a Submit review button on the detail screen',
    ($) async {
      final title = _uniqueTitle('prompt');
      await _setupCompletedJob($, title: title);

      await _openCompletedJobAsClient($, title);

      expect(find.byType(JobDetailScreen), findsOneWidget);
      expect(find.text('Completed'), findsWidgets);
      expect(
        find.byKey(const Key('clientActionBar.submitReviewButton')),
        findsOneWidget,
      );
      expect(find.text('Submit review'), findsOneWidget);
    },
  );

  // UAT #2 — "Given I'm on the review screen, when I submit without selecting
  // stars, then an error is shown and submission is blocked."
  patrolTest(
    'submitting the review sheet without a rating shows a validation error',
    ($) async {
      final title = _uniqueTitle('no-rating');
      await _setupCompletedJob($, title: title);

      await _openCompletedJobAsClient($, title);
      await $(
        find.byKey(const Key('clientActionBar.submitReviewButton')),
      ).tap();
      await $.pumpAndTrySettle(timeout: const Duration(seconds: 10));

      expect(find.textContaining('Rate '), findsOneWidget);

      await $(find.byKey(const Key('reviewSheet.submitButton'))).tap();
      await $.pumpAndTrySettle(timeout: const Duration(seconds: 10));

      expect(find.text('Please pick a rating.'), findsOneWidget);
      // Button must remain on the review card — the sheet did not close
      // and the action bar still shows the original submit button.
      expect(find.byKey(const Key('reviewSheet.submitButton')), findsOneWidget);
    },
  );

  // UAT #1 (full submission) + UAT #4 — after submitting, the option is no
  // longer available on the same job and the review card shows the rating.
  patrolTest(
    'client submits a 5-star review and cannot review the same job twice',
    ($) async {
      final title = _uniqueTitle('submit');
      await _setupCompletedJob($, title: title);

      await _openCompletedJobAsClient($, title);
      await $(
        find.byKey(const Key('clientActionBar.submitReviewButton')),
      ).tap();
      await $.pumpAndTrySettle(timeout: const Duration(seconds: 10));

      await $(find.byKey(const Key('reviewSheet.starButton_5'))).tap();
      await $(
        find.byKey(const Key('reviewSheet.commentField')),
      ).enterText('Patrol UAT — great job, very fast.');
      await $(find.byKey(const Key('reviewSheet.submitButton'))).tap();

      await $.pumpAndTrySettle(timeout: const Duration(seconds: 20));

      // Action bar flips to the disabled "Review submitted" label.
      expect(find.text('Review submitted'), findsOneWidget);
      expect(find.text('Submit review'), findsNothing);

      // The review card on the detail screen now shows the submitted review.
      expect(find.textContaining('Your review of'), findsOneWidget);
      expect(
        find.text('Patrol UAT — great job, very fast.'),
        findsOneWidget,
      );
    },
  );

  // UAT #3 — "Given I submit a review, when I visit the provider's profile,
  // then my rating and comment are visible."
  patrolTest(
    'submitted review appears on the provider profile screen',
    ($) async {
      final title = _uniqueTitle('visible');
      final comment = 'Patrol UAT — visible on profile. ($title)';

      await _setupCompletedJob($, title: title);

      // Submit the review as the client.
      await _openCompletedJobAsClient($, title);
      await $(
        find.byKey(const Key('clientActionBar.submitReviewButton')),
      ).tap();
      await $.pumpAndTrySettle(timeout: const Duration(seconds: 10));
      await $(find.byKey(const Key('reviewSheet.starButton_4'))).tap();
      await $(
        find.byKey(const Key('reviewSheet.commentField')),
      ).enterText(comment);
      await $(find.byKey(const Key('reviewSheet.submitButton'))).tap();
      await $.pumpAndTrySettle(timeout: const Duration(seconds: 20));

      // Switch to the provider and open their profile.
      await _logoutToLogin($);
      await _loginAsProfessional($);
      await $(find.byKey(const Key('bottomNavItem_profile'))).tap();
      await $(find.byType(ProProfileScreen)).waitUntilVisible(
        timeout: const Duration(seconds: 20),
      );
      await $.pumpAndTrySettle(timeout: const Duration(seconds: 10));

      // The reviews section header is rendered with an average rating value
      // (any non-dash digit indicates at least one review exists).
      expect(find.text('CLIENT REVIEWS'), findsOneWidget);
      await $(find.text(comment)).scrollTo();
      expect(find.text(comment), findsOneWidget);
    },
  );
}
