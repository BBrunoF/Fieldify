import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project/main.dart' as app;
import 'package:project/screens/home/home_screen.dart';

void main() {
  const testEmail    = 'bruno@gmail.com';
  const testPassword = 'teste123password';

  patrolSetUp(() async {
    final client = Supabase.instance.client;

    // limpar sessão antes de cada teste
    if (client.auth.currentSession != null) {
      await client.auth.signOut();
    }
  });

  patrolTearDown(() async {
    final client = Supabase.instance.client;

    // limpar sessão depois de cada teste
    if (client.auth.currentSession != null) {
      await client.auth.signOut();
    }
  });

  // testar login válido
  patrolTest(
    'login válido navega para HomeScreen',
    ($) async {
      await $.pumpWidgetAndSettle(app.FieldifyApp());

      await $(find.byKey(const Key('emailField'))).enterText(testEmail);
      await $(find.byKey(const Key('passwordField'))).enterText(testPassword);

      await $(find.byKey(const Key('loginButton'))).tap();

      // esperar rebuild do AuthGate
      await $.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  // testar password errada
  patrolTest(
    'login com password errada mostra erro',
    ($) async {
      await $.pumpWidgetAndSettle(app.FieldifyApp());

      await $(find.byKey(const Key('emailField'))).enterText(testEmail);
      await $(find.byKey(const Key('passwordField')))
          .enterText('wrongpassword');

      await $(find.byKey(const Key('loginButton'))).tap();

      await $.pumpAndSettle();

      // continua na login
      expect($(find.byKey(const Key('loginButton'))).exists, isTrue);

      // existe texto de erro
      expect(
        find.byWidgetPredicate((w) =>
            w is Text &&
            (w.data ?? '').toLowerCase().contains('invalid')),
        findsWidgets,
      );
    },
  );

  // testar campos vazios
  patrolTest(
    'login com campos vazios não crasha',
    ($) async {
      await $.pumpWidgetAndSettle(app.FieldifyApp());

      await $(find.byKey(const Key('loginButton'))).tap();

      await $.pumpAndSettle();

      expect($(find.byKey(const Key('loginButton'))).exists, isTrue);
    },
  );

  // testar toggle password
  patrolTest(
    'toggle da password funciona',
    ($) async {
      await $.pumpWidgetAndSettle(app.FieldifyApp());

      await $(find.byKey(const Key('passwordField')))
          .enterText('minha_password');

      // mostrar password
      await $(find.byIcon(Icons.visibility_outlined)).tap();
      await $.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // esconder password
      await $(find.byIcon(Icons.visibility_off_outlined)).tap();
      await $.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    },
  );

  // testar navegação para register
  patrolTest(
    'tap em Sign up navega para RegisterScreen',
    ($) async {
      await $.pumpWidgetAndSettle(app.FieldifyApp());

      await $(find.text('Sign up')).tap();

      await $.pumpAndSettle();

      expect(find.text('Create account'), findsOneWidget);
    },
  );
}