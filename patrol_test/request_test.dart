import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project/main.dart' as app;

const _email = 'test@fieldify.dev';
const _password = 'Test1234!';

void main() {
  patrolSetUp(() async {
    await app.bootstrap();

    final client = Supabase.instance.client;

    if (client.auth.currentSession != null) {
      await client.auth.signOut();
    }

    await client.auth.signInWithPassword(
      email: _email,
      password: _password,
    );
  });

  patrolTearDown(() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    if (userId != null) {
      await client
          .from('service_requests')
          .delete()
          .eq('client_id', userId)
          .eq('title', 'Leaking pipe under kitchen sink');
    }

    if (client.auth.currentSession != null) {
      await client.auth.signOut();
    }
  });

  patrolTest('home abre com utilizador autenticado', ($) async {
    await $.pumpWidgetAndSettle(const app.FieldifyApp());
    await $.pump(const Duration(seconds: 2));

    expect(find.byKey(const Key('goToRequestButton')), findsOneWidget);
  });

  patrolTest('abre request screen a partir da home', ($) async {
    await $.pumpWidgetAndSettle(const app.FieldifyApp());
    await $.pump(const Duration(seconds: 2));

    await $(find.byKey(const Key('goToRequestButton'))).tap();
    await $.pumpAndSettle();

    expect(find.textContaining('Plumbing'), findsWidgets);
  });

  patrolTest('submete pedido completo', ($) async {
    await $.pumpWidgetAndSettle(const app.FieldifyApp());
    await $.pump(const Duration(seconds: 2));

    await $(find.byKey(const Key('goToRequestButton'))).tap();
    await $.pumpAndSettle();

    await $(find.text('Continue')).tap();
    await $.pumpAndSettle();

    await $(find.text('Continue')).tap();
    await $.pumpAndSettle();

    await $(find.text('Continue')).tap();
    await $.pumpAndSettle();

    await $(find.text('Submit request')).tap();
    await $.pumpAndSettle();
    await $.pump(const Duration(seconds: 3));

    expect(find.text('Request submitted'), findsOneWidget);
    expect(find.text('Track job'), findsOneWidget);
  });

  patrolTest('seleciona Electrical', ($) async {
    await $.pumpWidgetAndSettle(const app.FieldifyApp());
    await $.pump(const Duration(seconds: 2));

    await $(find.byKey(const Key('goToRequestButton'))).tap();
    await $.pumpAndSettle();

    await $(find.text('Electrical')).tap();
    await $(find.text('Continue')).tap();
    await $.pumpAndSettle();

    await $(find.text('Continue')).tap();
    await $.pumpAndSettle();

    await $(find.text('Continue')).tap();
    await $.pumpAndSettle();

    expect(find.text('Electrical'), findsWidgets);
  });

  patrolTest('ativa schedule', ($) async {
    await $.pumpWidgetAndSettle(const app.FieldifyApp());
    await $.pump(const Duration(seconds: 2));

    await $(find.byKey(const Key('goToRequestButton'))).tap();
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
  });

  patrolTest('back to home funciona', ($) async {
    await $.pumpWidgetAndSettle(const app.FieldifyApp());
    await $.pump(const Duration(seconds: 2));

    await $(find.byKey(const Key('goToRequestButton'))).tap();
    await $.pumpAndSettle();

    await $(find.text('Continue')).tap();
    await $.pumpAndSettle();

    await $(find.text('Continue')).tap();
    await $.pumpAndSettle();

    await $(find.text('Continue')).tap();
    await $.pumpAndSettle();

    await $(find.text('Submit request')).tap();
    await $.pumpAndSettle();
    await $.pump(const Duration(seconds: 2));

    expect(find.text('Request submitted'), findsOneWidget);

    await $(find.text('Back to home')).tap();
    await $.pumpAndSettle();

    expect(find.text('Request submitted'), findsNothing);
  });
}