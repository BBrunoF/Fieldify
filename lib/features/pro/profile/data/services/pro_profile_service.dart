import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/supabase/supabase_client.dart';
import '../models/pro_profile_model.dart';

const _avatarBucket = 'profile-photos';
const _signedUrlTtl = 3600;

class ProProfileService {
  Future<ProProfileModel?> fetchCurrent() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final row = await supabase
        .from('profiles')
        .select(
          'full_name, avatar_url, '
          'professional_profiles(nif, bio, verification_status, trades(display_name, standard_rate))',
        )
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) return null;

    final proData = row['professional_profiles'];
    final Map<String, dynamic>? proRow = proData is List
        ? (proData.isNotEmpty ? proData.first as Map<String, dynamic> : null)
        : proData as Map<String, dynamic>?;

    if (proRow == null) return null;

    final tradeData = proRow['trades'];
    final Map<String, dynamic> tradeRow = tradeData is List
        ? (tradeData.isNotEmpty ? tradeData.first as Map<String, dynamic> : {})
        : (tradeData as Map<String, dynamic>? ?? {});

    return ProProfileModel(
      fullName: (row['full_name'] ?? '') as String,
      nif: (proRow['nif'] ?? '') as String,
      bio: (proRow['bio'] ?? '') as String,
      verificationStatus: (proRow['verification_status'] ?? 'pending') as String,
      avatarPath: row['avatar_url'] as String?,
      tradeName: (tradeRow['display_name'] ?? '') as String,
      standardRate: (tradeRow['standard_rate'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> updateProfile({
    required String bio,
    String? fullName,
    String? nif,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');

    final proRow = await supabase
        .from('professional_profiles')
        .select('verification_status')
        .eq('profile_id', user.id)
        .maybeSingle();

    final isApproved = (proRow?['verification_status'] ?? '') == 'approved';

    await supabase.from('professional_profiles').update({
      'bio': bio.trim(),
      if (!isApproved && nif != null) 'nif': nif.trim(),
    }).eq('profile_id', user.id);

    if (!isApproved && fullName != null && fullName.trim().isNotEmpty) {
      await supabase
          .from('profiles')
          .update({'full_name': fullName.trim()})
          .eq('id', user.id);
    }
  }

  Future<String> uploadAvatar({required File file}) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');

    final ext = file.path.split('.').last.toLowerCase();
    final path = '${user.id}/avatar.$ext';

    await supabase.storage
        .from(_avatarBucket)
        .upload(path, file, fileOptions: const FileOptions(upsert: true));

    await supabase
        .from('profiles')
        .update({'avatar_url': path})
        .eq('id', user.id);

    return path;
  }

  Future<String?> getSignedAvatarUrl(String path) async {
    try {
      return await supabase.storage
          .from(_avatarBucket)
          .createSignedUrl(path, _signedUrlTtl);
    } catch (_) {
      return null;
    }
  }
}
