import '../../../../core/supabase/supabase_client.dart';

class HomeService {
  Future<bool> fetchIsProfessional() async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    final profile = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    return profile != null && profile['role'] == 'professional';
  }
}
