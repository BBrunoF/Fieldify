import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/auth/controllers/auth_controller.dart';
import 'package:project/features/auth/data/repositories/auth_repository.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.onSignIn, this.onSignUp, this.onSignOut});

  final Future<void> Function({
    required String email,
    required String password,
  })?
  onSignIn;
  final Future<void> Function({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  })?
  onSignUp;
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
  }) async {
    await onSignUp?.call(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );
  }

  @override
  Future<void> signOut() async {
    await onSignOut?.call();
  }
}

void main() {
  group('AuthController', () {
    test('signIn toggles loading state and clears errors on success', () async {
      final states = <bool>[];
      final controller = AuthController(
        repo: _FakeAuthRepository(
          onSignIn: ({required email, required password}) async {
            expect(email, 'user@test.com');
            expect(password, 'secret123');
          },
        ),
      );

      controller.addListener(() => states.add(controller.isLoading));

      await controller.signIn(email: 'user@test.com', password: 'secret123');

      expect(states, [true, false]);
      expect(controller.error, isNull);
      expect(controller.isLoading, isFalse);
    });

    test('signUp exposes repository failures as UI error state', () async {
      final controller = AuthController(
        repo: _FakeAuthRepository(
          onSignUp:
              ({
                required email,
                required password,
                required firstName,
                required lastName,
                required phone,
              }) async {
                throw const AuthFailure('Email already in use');
              },
        ),
      );

      await controller.signUp(
        email: 'user@test.com',
        password: 'secret123',
        firstName: 'User',
        lastName: 'Test',
        phone: '+351900000000',
      );

      expect(controller.isLoading, isFalse);
      expect(controller.error, 'Email already in use');
    });

    test('signOut delegates to the repository', () async {
      var called = false;
      final controller = AuthController(
        repo: _FakeAuthRepository(
          onSignOut: () async {
            called = true;
          },
        ),
      );

      await controller.signOut();

      expect(called, isTrue);
    });
  });
}
