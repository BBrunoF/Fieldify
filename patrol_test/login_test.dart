import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project/main.dart' as app;
import 'package:project/screens/home/home_screen.dart';

void main() {
  const testEmail = 'bruno@gmail.com';
  const testPassword = 'teste123password';

  patrolSetUp(() async {
    await app.bootstrap();

    final client = Supabase.instance.client;
    if (client.auth.currentSession != null) {
      await client.auth.signOut();
    }
  });

  patrolTearDown(() async {
    final client = Supabase.instance.client;
    if (client.auth.currentSession != null) {
      await client.auth.signOut();
    }
  });

  patrolTest('login screen abre', ($) async {
    await $.pumpWidgetAndSettle(const app.FieldifyApp());
    await $.pump(const Duration(seconds: 2));

    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
    expect(find.byKey(const Key('loginButton')), findsOneWidget);
  });

  patrolTest('login válido navega para HomeScreen', ($) async {
    await $.pumpWidgetAndSettle(const app.FieldifyApp());
    await $.pump(const Duration(seconds: 2));

    await $(find.byKey(const Key('emailField'))).enterText(testEmail);
    await $(find.byKey(const Key('passwordField'))).enterText(testPassword);
    await $(find.byKey(const Key('loginButton'))).tap();

    await $.pumpAndSettle();
    await $.pump(const Duration(seconds: 3));

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  patrolTest('login com password errada mostra erro', ($) async {
    await $.pumpWidgetAndSettle(const app.FieldifyApp());
    await $.pump(const Duration(seconds: 2));

    await $(find.byKey(const Key('emailField'))).enterText(testEmail);
    await $(find.byKey(const Key('passwordField'))).enterText('wrongpassword');
    await $(find.byKey(const Key('loginButton'))).tap();

    await $.pumpAndSettle();
    await $.pump(const Duration(seconds: 2));

    expect(find.text('Invalid login credentials'), findsOneWidget);
  });

  patrolTest('login com campos vazios não crasha', ($) async {
    await $.pumpWidgetAndSettle(const app.FieldifyApp());
    await $.pump(const Duration(seconds: 2));

    await $(find.byKey(const Key('loginButton'))).tap();
    await $.pumpAndSettle();

    expect(find.byKey(const Key('loginButton')), findsOneWidget);
  });

  patrolTest('toggle da password funciona', ($) async {
    await $.pumpWidgetAndSettle(const app.FieldifyApp());
    await $.pump(const Duration(seconds: 2));

    await $(find.byKey(const Key('passwordField'))).enterText('minha_password');

    await $(find.byIcon(Icons.visibility_outlined)).tap();
    await $.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

    await $(find.byIcon(Icons.visibility_off_outlined)).tap();
    await $.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });

  patrolTest('tap em Sign up navega para RegisterScreen', ($) async {
    await $.pumpWidgetAndSettle(const app.FieldifyApp());
    await $.pump(const Duration(seconds: 2));

    await $(find.text('Sign up')).tap();
    await $.pumpAndSettle();

    expect(find.text('Create account'), findsOneWidget);
  });
}