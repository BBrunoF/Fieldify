import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/supabase/supabase_client.dart';
import '../models/pro_profile_model.dart';

const _avatarBucket = 'profile-photos';
const _credentialsBucket = 'credentials';
const _signedUrlTtl = 3600;

class ProProfileService {
  Future<ProProfileModel?> fetchCurrent() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final row = await supabase
        .from('profiles')
        .select(
          'full_name, avatar_url, '
          'professional_profiles(nif, bio, verification_status, service_radius_km, credential_urls, trades(display_name, standard_rate))',
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

    final rawUrls = proRow['credential_urls'];
    final credentialUrls = rawUrls is List
        ? rawUrls.map((e) => e.toString()).toList()
        : <String>[];

    return ProProfileModel(
      fullName: (row['full_name'] ?? '') as String,
      nif: (proRow['nif'] ?? '') as String,
      bio: (proRow['bio'] ?? '') as String,
      verificationStatus: (proRow['verification_status'] ?? 'pending') as String,
      avatarPath: row['avatar_url'] as String?,
      tradeName: (tradeRow['display_name'] ?? '') as String,
      standardRate: (tradeRow['standard_rate'] as num?)?.toInt() ?? 0,
      credentialUrls: credentialUrls,
      serviceRadiusKm: (proRow['service_radius_km'] as num?)?.toInt(),
    );
  }

  Future<void> updateProfile({
    required String bio,
    required int? serviceRadiusKm,
    String? fullName,
    String? nif,
    List<String>? credentialUrls,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');

    final proRow = await supabase
        .from('professional_profiles')
        .select('verification_status')
        .eq('profile_id', user.id)
        .maybeSingle();

    if (proRow == null) throw const AuthException('Professional profile not found');

    final isApproved = (proRow['verification_status'] ?? '') == 'approved';

    final updated = await supabase
        .from('professional_profiles')
        .update({
          'bio': bio.trim(),
          'service_radius_km': serviceRadiusKm,
          if (!isApproved && nif != null) 'nif': nif.trim(),
          if (!isApproved && credentialUrls != null)
            'credential_urls': credentialUrls,
        })
        .eq('profile_id', user.id)
        .select('profile_id');

    if (updated.isEmpty) throw const AuthException('Update failed — check Supabase RLS policies');

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

  /// Uploads a credential document to the private `credentials` bucket and
  /// returns its storage path. The path is `{user.id}/{uuid}_{filename}`, which
  /// keeps the original name visible while staying unique and matching the
  /// per-user RLS folder convention.
  Future<String> uploadCredential({
    required File file,
    required String filename,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');

    final safeName = filename.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = '${user.id}/${const Uuid().v4()}_$safeName';

    await supabase.storage.from(_credentialsBucket).upload(path, file);

    return path;
  }

  Future<void> deleteCredential(String path) async {
    await supabase.storage.from(_credentialsBucket).remove([path]);
  }

  Future<String?> getSignedCredentialUrl(String path) async {
    try {
      return await supabase.storage
          .from(_credentialsBucket)
          .createSignedUrl(path, _signedUrlTtl);
    } catch (_) {
      return null;
    }
  }
}
