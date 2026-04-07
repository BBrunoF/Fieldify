import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _client = Supabase.instance.client;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': '$firstName $lastName',
        'phone': phone,
        'role': 'client',
      },
    );
  }

  Future<void> signOut() => _client.auth.signOut();
}