import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/auth/data/repositories/auth_repository.dart';
import 'package:project/features/auth/data/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService({this.onSignIn, this.onSignOut});

  final Future<void> Function({
    required String email,
    required String password,
  })?
  onSignIn;
  final Future<void> Function()? onSignOut;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await onSignIn?.call(email: email, password: password);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {}

  @override
  Future<void> signOut() async {
    await onSignOut?.call();
  }
}

void main() {
  group('AuthRepository', () {
    test('maps AuthException from signIn into AuthFailure', () async {
      final repository = AuthRepository(
        service: _FakeAuthService(
          onSignIn: ({required email, required password}) async {
            throw const AuthException('Invalid login credentials');
          },
        ),
      );

      await expectLater(
        () => repository.signIn(email: 'user@test.com', password: 'bad-pass'),
        throwsA(
          isA<AuthFailure>().having(
            (error) => error.message,
            'message',
            'Invalid login credentials',
          ),
        ),
      );
    });

    test('maps AuthException from signOut into AuthFailure', () async {
      final repository = AuthRepository(
        service: _FakeAuthService(
          onSignOut: () async {
            throw const AuthException('Could not sign out');
          },
        ),
      );

      await expectLater(
        repository.signOut,
        throwsA(
          isA<AuthFailure>().having(
            (error) => error.message,
            'message',
            'Could not sign out',
          ),
        ),
      );
    });
  });
}
