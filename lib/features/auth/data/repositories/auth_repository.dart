import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => message;
}

class AuthRepository {
  final AuthService _service;

  AuthRepository({AuthService? service}) : _service = service ?? AuthService();

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _service.signIn(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      await _service.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<void> signOut() async {
    try {
      await _service.signOut();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }
}
