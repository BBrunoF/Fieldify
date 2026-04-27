import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/supabase/supabase_client.dart';
import '../models/profile_model.dart';

class ProfileService {
  Future<ProfileModel?> fetchCurrent() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    final meta = Map<String, dynamic>.from(user.userMetadata ?? {});
    try {
      final data = await supabase
          .from('profiles')
          .select('full_name, phone')
          .eq('id', user.id)
          .maybeSingle();
      return ProfileModel(
        fullName: data?['full_name'] as String? ?? meta['full_name'] as String? ?? '',
        phone: data?['phone'] as String? ?? meta['phone'] as String? ?? '',
        email: user.email ?? '',
        addresses: meta['addresses'] is List
            ? List<String>.from(meta['addresses'] as List)
            : [],
      );
    } catch (_) {
      return ProfileModel.fromMeta(meta, user.email ?? '');
    }
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required List<String> addresses,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');

    final fullName = '${firstName.trim()} ${lastName.trim()}';
    final meta = Map<String, dynamic>.from(user.userMetadata ?? {});

    await Future.wait<dynamic>([
      supabase.auth.updateUser(
        UserAttributes(
          data: {
            ...meta,
            'full_name': fullName,
            'phone': phone.trim(),
            'addresses': addresses,
          },
        ),
      ),
      supabase.from('profiles').update({
        'full_name': fullName,
        'phone': phone.trim(),
      }).eq('id', user.id),
    ]);
  }
}
