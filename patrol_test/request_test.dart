import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project/main.dart' as app;
import 'package:project/screens/home/home_screen.dart';

const _email    = 'test@fieldify.dev';
const _password = 'Test1234!';

void main() {
  patrolSetUp(() async {
    final client = Supabase.instance.client;

    // garantir sessão válida
    if (client.auth.currentSession == null) {
      await client.auth.signInWithPassword(
        email: _email,
        password: _password,
      );
    }
  });

  patrolTearDown(() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    // limpar dados criados no teste
    if (userId != null) {
      await client
          .from('service_requests')
          .delete()
          .eq('client_id', userId)
          .eq('title', 'Leaking pipe under kitchen sink');
    }
  });

  // fluxo completo
  patrolTest(
    'submete pedido completo',
    ($) async {
      // usar widget em vez de main()
      await $.pumpWidgetAndSettle(app.FieldifyApp());

      await $(find.text('New request')).tap();
      await $.pumpAndSettle();

      // step 1
      expect(find.text('Plumbing'), findsOneWidget);
      await $(find.text('Continue')).tap();
      await $.pumpAndSettle();

      // step 2
      expect(find.text('Leaking pipe under kitchen sink'), findsOneWidget);
      await $(find.text('Continue')).tap();
      await $.pumpAndSettle();

      // step 3
      expect(find.text('Rua do Heroísmo 42, Porto'), findsOneWidget);
      await $(find.text('Continue')).tap();
      await $.pumpAndSettle();

      // step 4
      expect(find.text('Plumbing'), findsOneWidget);

      await $(find.text('Submit request')).tap();

      // esperar resposta do supabase
      await $.pumpAndSettle();

      // sucesso
      expect(find.text('Request submitted'), findsOneWidget);
      expect(find.text('Track job'), findsOneWidget);
    },
  );

  // categoria diferente
  patrolTest(
    'seleciona Electrical',
    ($) async {
      await $.pumpWidgetAndSettle(app.FieldifyApp());

      await $(find.text('New request')).tap();
      await $.pumpAndSettle();

      await $(find.text('Electrical')).tap();
      await $(find.text('Continue')).tap();
      await $.pumpAndSettle();

      await $(find.text('Continue')).tap();
      await $.pumpAndSettle();

      await $(find.text('Continue')).tap();
      await $.pumpAndSettle();

      expect(find.text('Electrical'), findsOneWidget);
    },
  );

  // schedule
  patrolTest(
    'ativa schedule',
    ($) async {
      await $.pumpWidgetAndSettle(app.FieldifyApp());

      await $(find.text('New request')).tap();
      await $.pumpAndSettle();

      await $(find.text('Continue')).tap();
      await $.pumpAndSettle();

      await $(find.text('Continue')).tap();
      await $.pumpAndSettle();

      await $(find.text('Schedule')).tap();
      await $.pumpAndSettle();

      expect(
        find.text('Date').evaluate().isNotEmpty ||
            find.text('DATE').evaluate().isNotEmpty,
        isTrue,
      );

      await $(find.text('Continue')).tap();
      await $.pumpAndSettle();
    },
  );

  // voltar para home
  patrolTest(
    'back to home funciona',
    ($) async {
      await $.pumpWidgetAndSettle(app.FieldifyApp());

      await $(find.text('New request')).tap();
      await $.pumpAndSettle();

      // navegar rápido pelos steps
      for (final label in ['Continue', 'Continue', 'Continue']) {
        await $(find.text(label)).tap();
        await $.pumpAndSettle();
      }

      await $(find.text('Submit request')).tap();
      await $.pumpAndSettle();

      expect(find.text('Request submitted'), findsOneWidget);

      await $(find.text('Back to home')).tap();
      await $.pumpAndSettle();

      expect(find.text('Request submitted'), findsNothing);
    },
  );
}