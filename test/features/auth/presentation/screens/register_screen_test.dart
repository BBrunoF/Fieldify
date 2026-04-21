import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/auth/controllers/auth_controller.dart';
import 'package:project/features/auth/data/repositories/auth_repository.dart';
import 'package:project/features/auth/presentation/screens/register_screen.dart';

import '../../../../test_helpers.dart';

class _CapturingAuthRepository extends AuthRepository {
  String? email;
  String? password;
  String? firstName;
  String? lastName;
  String? phone;

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    this.email = email;
    this.password = password;
    this.firstName = firstName;
    this.lastName = lastName;
    this.phone = phone;
  }
}

void main() {
  testWidgets('RegisterScreen sends trimmed values to the controller', (
    tester,
  ) async {
    final repository = _CapturingAuthRepository();
    final controller = AuthController(repo: repository);

    await pumpTestApp(tester, RegisterScreen(controller: controller));

    await tester.enterText(find.byType(TextFormField).at(0), ' Bruno ');
    await tester.enterText(find.byType(TextFormField).at(1), ' Silva ');
    await tester.enterText(find.byType(TextFormField).at(2), ' user@test.com ');
    await tester.enterText(
      find.byType(TextFormField).at(3),
      ' +351 912 000 000 ',
    );
    await tester.enterText(find.byType(TextFormField).at(4), 'secret123');

    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(repository.firstName, 'Bruno');
    expect(repository.lastName, 'Silva');
    expect(repository.email, 'user@test.com');
    expect(repository.phone, '+351 912 000 000');
    expect(repository.password, 'secret123');
  });
}
