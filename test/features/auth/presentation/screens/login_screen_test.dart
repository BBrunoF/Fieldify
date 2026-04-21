import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/auth/controllers/auth_controller.dart';
import 'package:project/features/auth/data/repositories/auth_repository.dart';
import 'package:project/features/auth/presentation/screens/login_screen.dart';

import '../../../../test_helpers.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.onSignIn});

  final Future<void> Function({
    required String email,
    required String password,
  })?
  onSignIn;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await onSignIn?.call(email: email, password: password);
  }
}

void main() {
  group('LoginScreen', () {
    testWidgets('shows repository error after failed sign in', (tester) async {
      final controller = AuthController(
        repo: _FakeAuthRepository(
          onSignIn: ({required email, required password}) async {
            throw const AuthFailure('Invalid login credentials');
          },
        ),
      );

      await pumpTestApp(tester, LoginScreen(controller: controller));

      await tester.enterText(
        find.byKey(const Key('emailField')),
        'user@test.com',
      );
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'wrong-pass',
      );
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pump();
      await tester.pump();

      expect(find.text('Invalid login credentials'), findsOneWidget);
    });

    testWidgets('shows a loader while sign in is running', (tester) async {
      final completer = Completer<void>();
      final controller = AuthController(
        repo: _FakeAuthRepository(
          onSignIn: ({required email, required password}) => completer.future,
        ),
      );

      await pumpTestApp(tester, LoginScreen(controller: controller));

      await tester.enterText(
        find.byKey(const Key('emailField')),
        'user@test.com',
      );
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'secret123',
      );
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('navigates to register screen from footer link', (
      tester,
    ) async {
      await pumpTestApp(tester, const LoginScreen());

      await tester.ensureVisible(find.text('Sign up'));
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      expect(find.text('Create account'), findsOneWidget);
      expect(find.text('Free to join, no commitments'), findsOneWidget);
    });
  });
}
