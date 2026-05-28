import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project/core/supabase/supabase_client.dart';
import 'package:project/features/home/presentation/screens/home_screen.dart';
import 'package:project/features/shared/chat/presentation/screens/chat_screen.dart';
import 'package:project/features/shared/chat/presentation/screens/inbox_screen.dart';
import 'package:project/features/pro/jobs/presentation/widgets/incoming_job_card.dart';
import 'package:project/main.dart' as app;

import 'fake_payments.dart';

const _clientEmail = 'client@client.com';
const _clientPassword = 'clientclient';
const _professionalEmail = 'test@test.com';
const _professionalPassword = 'testtest';

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
    find.byKey(const Key('bottomNavItem_messages')),
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

  await $(find.byKey(const Key('backToHomeButton'))).tap();
  await $(
    find.byKey(const Key('homeMainTab')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _openIncomingJobsTab(PatrolIntegrationTester $) async {
  await $(find.byKey(const Key('bottomNavItem_jobs'))).tap();
  await $(
    find.byKey(const Key('homeJobsHeader')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(
    find.byKey(const Key('proJobsTabIncoming')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(
    find.byKey(const Key('incomingJobsView')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

Finder _incomingActionFinder({required String title, required String label}) {
  return find.descendant(
    of: find.ancestor(
      of: find.text(title),
      matching: find.byType(IncomingJobCard),
    ),
    matching: find.text(label),
  );
}

Future<void> _acceptIncomingRequest(
  PatrolIntegrationTester $,
  String title,
) async {
  await $(title).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(_incomingActionFinder(title: title, label: 'Accept')).tap();

  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(deadline)) {
    await $.pump(const Duration(milliseconds: 250));
    if (find.text(title).evaluate().isEmpty) return;
  }
  fail('Incoming request "$title" was still visible after accepting it.');
}

Future<void> _openMessagesTab(PatrolIntegrationTester $) async {
  await $(find.byKey(const Key('bottomNavItem_messages'))).tap();
  await $(
    find.byType(InboxScreen),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

/// Waits for [title] to appear in the inbox. The first load can race with
/// a database write (e.g. right after the pro accepts a job), so this helper
/// pops the inbox and re-opens it once if the title does not show up quickly,
/// and scrolls the list if the conversation is below the fold.
Future<void> _waitForConversationTitle(
  PatrolIntegrationTester $,
  String title,
) async {
  final firstDeadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(firstDeadline)) {
    await $.pump(const Duration(milliseconds: 500));
    if (find.text(title).evaluate().isNotEmpty) return;
  }

  // Try scrolling the list in case the conversation is below the fold.
  try {
    await $(find.text(title))
        .scrollTo(view: find.byType(InboxScreen), step: 320, maxScrolls: 40);
    if (find.text(title).evaluate().isNotEmpty) return;
  } catch (_) {
    // ignore and fall through to a hard reload attempt
  }

  // Force a reload by leaving and re-entering the inbox.
  if (find.byKey(const Key('inboxBackButton')).evaluate().isNotEmpty) {
    await $(find.byKey(const Key('inboxBackButton'))).tap();
    await $(
      find.byKey(const Key('bottomNavItem_messages')),
    ).waitUntilVisible(timeout: const Duration(seconds: 10));
    await _openMessagesTab($);
  }

  try {
    await $(find.text(title))
        .scrollTo(view: find.byType(InboxScreen), step: 320, maxScrolls: 40);
  } catch (_) {}

  await $(title).waitUntilVisible(timeout: const Duration(seconds: 30));
}

Future<void> _openConversationByTitle(
  PatrolIntegrationTester $,
  String title,
) async {
  await _waitForConversationTitle($, title);
  await $(find.text(title)).tap();
  await $(
    find.byType(ChatScreen),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(
    find.byKey(const Key('chatInputField')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _sendChatMessage(
  PatrolIntegrationTester $,
  String content,
) async {
  await $(find.byKey(const Key('chatInputField'))).enterText(content);
  await $(find.byKey(const Key('chatSendButton'))).tap();
  await $(content).waitUntilVisible(timeout: const Duration(seconds: 20));
}

/// Proposes a reschedule from the chat composer. The native date and time
/// pickers open in sequence; we accept their defaults (tomorrow at the top of
/// the current hour, which is always in the future) by tapping "OK" twice.
/// Leaves the chat showing the freshly created reschedule card.
Future<void> _proposeReschedule(PatrolIntegrationTester $) async {
  await $(find.byKey(const Key('proposeRescheduleButton'))).tap();

  // Date picker.
  await $(find.text('OK')).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(find.text('OK')).tap();

  // Time picker.
  await $(find.text('OK')).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(find.text('OK')).tap();

  await $(
    find.text('RESCHEDULE REQUEST'),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

Future<void> _respondToReschedule(
  PatrolIntegrationTester $, {
  required bool accept,
}) async {
  final buttonKey = accept ? 'rescheduleAcceptButton' : 'rescheduleRejectButton';
  await $(
    find.byKey(Key(buttonKey)),
  ).waitUntilVisible(timeout: const Duration(seconds: 30));
  await $(find.byKey(Key(buttonKey))).tap();
}

Future<void> _leaveChatToHome(PatrolIntegrationTester $) async {
  if (find.byKey(const Key('chatBackButton')).evaluate().isNotEmpty) {
    await $(find.byKey(const Key('chatBackButton'))).tap();
  }
  if (find.byKey(const Key('inboxBackButton')).evaluate().isNotEmpty) {
    await $(find.byKey(const Key('inboxBackButton'))).tap();
  }
  await $(
    find.byKey(const Key('bottomNavItem_home')),
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
}

String _uniqueChatTitle(String scenario) {
  final millis = DateTime.now().millisecondsSinceEpoch;
  return 'Patrol chat $scenario $millis';
}

void main() {
  patrolSetUp(_signOutIfNeeded);
  patrolTearDown(_signOutIfNeeded);

  patrolTest('Messages tab is reachable from the bottom navigation', (
    $,
  ) async {
    await _loginAsClient($);
    await _openMessagesTab($);

    expect(find.byType(InboxScreen), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
  });

  patrolTest(
    'client and professional exchange a message in an active job chat',
    ($) async {
      final title = _uniqueChatTitle('exchange');
      final messageFromPro = 'Hello from the pro $title';
      final messageFromClient = 'Reply from the client $title';
      const description = 'Patrol generated request for chat flow.';
      const address = 'Rua de Cedofeita 100, Porto';

      // 1. Client submits a request.
      await _loginAsClient($);
      await _submitRequestAsClient(
        $,
        title: title,
        description: description,
        address: address,
      );
      await _logoutToLogin($);

      // 2. Professional accepts the request, opens the chat and sends a message.
      await _loginAsProfessional($);
      await _openIncomingJobsTab($);
      await _acceptIncomingRequest($, title);

      await _openMessagesTab($);
      await _openConversationByTitle($, title);
      await _sendChatMessage($, messageFromPro);
      expect(find.text(messageFromPro), findsOneWidget);

      await _leaveChatToHome($);
      await _logoutToLogin($);

      // 3. Client opens the same conversation and sees the pro's message,
      //    then replies.
      await _loginAsClient($);
      await _openMessagesTab($);
      await _openConversationByTitle($, title);
      await $(messageFromPro)
          .waitUntilVisible(timeout: const Duration(seconds: 30));
      expect(find.text(messageFromPro), findsOneWidget);

      await _sendChatMessage($, messageFromClient);
      expect(find.text(messageFromClient), findsOneWidget);
    },
  );

  patrolTest(
    'professional proposes a reschedule and the client accepts it',
    ($) async {
      final title = _uniqueChatTitle('reschedule-accept');
      const description = 'Patrol generated request for reschedule accept.';
      const address = 'Rua de Cedofeita 100, Porto';

      // 1. Client submits a request.
      await _loginAsClient($);
      await _submitRequestAsClient(
        $,
        title: title,
        description: description,
        address: address,
      );
      await _logoutToLogin($);

      // 2. Professional accepts the job and proposes a reschedule.
      await _loginAsProfessional($);
      await _openIncomingJobsTab($);
      await _acceptIncomingRequest($, title);

      await _openMessagesTab($);
      await _openConversationByTitle($, title);
      await _proposeReschedule($);
      // The proposer sees a pending card, not the accept/decline buttons.
      expect(find.text('Waiting for a response…'), findsOneWidget);
      expect(find.byKey(const Key('rescheduleAcceptButton')), findsNothing);

      await _leaveChatToHome($);
      await _logoutToLogin($);

      // 3. Client opens the chat, sees the proposal and accepts it.
      await _loginAsClient($);
      await _openMessagesTab($);
      await _openConversationByTitle($, title);
      await _respondToReschedule($, accept: true);

      await $(
        find.text('Accepted — schedule updated'),
      ).waitUntilVisible(timeout: const Duration(seconds: 30));
      expect(find.text('Accepted — schedule updated'), findsOneWidget);
    },
  );

  patrolTest(
    'professional proposes a reschedule and the client declines it',
    ($) async {
      final title = _uniqueChatTitle('reschedule-decline');
      const description = 'Patrol generated request for reschedule decline.';
      const address = 'Rua de Cedofeita 100, Porto';

      // 1. Client submits a request.
      await _loginAsClient($);
      await _submitRequestAsClient(
        $,
        title: title,
        description: description,
        address: address,
      );
      await _logoutToLogin($);

      // 2. Professional accepts the job and proposes a reschedule.
      await _loginAsProfessional($);
      await _openIncomingJobsTab($);
      await _acceptIncomingRequest($, title);

      await _openMessagesTab($);
      await _openConversationByTitle($, title);
      await _proposeReschedule($);

      await _leaveChatToHome($);
      await _logoutToLogin($);

      // 3. Client opens the chat, sees the proposal and declines it.
      await _loginAsClient($);
      await _openMessagesTab($);
      await _openConversationByTitle($, title);
      await _respondToReschedule($, accept: false);

      await $(
        find.text('Declined — original time kept'),
      ).waitUntilVisible(timeout: const Duration(seconds: 30));
      expect(find.text('Declined — original time kept'), findsOneWidget);
    },
  );
}
