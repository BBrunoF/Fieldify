import '../../../../core/supabase/supabase_client.dart';

class AuthService {
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await supabase.auth.signInWithPassword(
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
    await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': '$firstName $lastName',
        'phone': phone,
        'role': 'client',
      },
    );
  }

  Future<void> signOut() => supabase.auth.signOut();
}
