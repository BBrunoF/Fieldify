import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project/core/notifications/notification_service.dart';
import 'package:project/core/supabase/supabase_client.dart';
import 'package:project/features/home/presentation/screens/home_screen.dart';
import 'package:project/main.dart' as app;

const _clientEmail = 'client@client.com';
const _clientPassword = 'clientclient';

Future<void> _bootstrapApp() async {
  await initializeSupabase();
  await Firebase.initializeApp();
  await NotificationService.instance.initialize();
}

Future<void> _signOutIfNeeded() async {
  await _bootstrapApp();
  final auth = Supabase.instance.client.auth;
  if (auth.currentSession != null) {
    await auth.signOut();
  }
}

Future<void> _loginAsClient(PatrolIntegrationTester $) async {
  await _bootstrapApp();
  await $.pumpWidgetAndSettle(const app.FieldifyApp());

  await $(find.byKey(const Key('emailField')))
      .waitUntilVisible(timeout: const Duration(seconds: 20));

  await $(find.byKey(const Key('emailField'))).enterText(_clientEmail);
  await $(find.byKey(const Key('passwordField'))).enterText(_clientPassword);
  await $(find.byKey(const Key('loginButton'))).tap();

  await $.pumpAndTrySettle(timeout: const Duration(seconds: 20));
  expect(find.byType(HomeScreen), findsOneWidget);
}

void main() {
  patrolSetUp(_signOutIfNeeded);
  patrolTearDown(_signOutIfNeeded);

  patrolTest(
    'client can grant notification permissions on first launch',
    ($) async {
      await _loginAsClient($);

      // The permission dialog appears automatically after login on Android 13+.
      // We grant it and confirm the app continues normally.
      if (await $.platformAutomator.mobile.isPermissionDialogVisible(
        timeout: const Duration(seconds: 8),
      )) {
        await $.platformAutomator.mobile.grantPermissionWhenInUse();
      }

      await $.pumpAndTrySettle(timeout: const Duration(seconds: 5));
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  patrolTest(
    'client can deny notification permissions and app continues to work',
    ($) async {
      await _loginAsClient($);

      if (await $.platformAutomator.mobile.isPermissionDialogVisible(
        timeout: const Duration(seconds: 8),
      )) {
        await $.platformAutomator.mobile.denyPermission();
      }

      await $.pumpAndTrySettle(timeout: const Duration(seconds: 5));
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );
}
