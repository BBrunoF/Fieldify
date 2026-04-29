import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pro_profile_model.dart';
import '../services/pro_profile_service.dart';

class ProProfileFailure implements Exception {
  final String message;
  const ProProfileFailure(this.message);

  @override
  String toString() => message;
}

class ProProfileRepository {
  final ProProfileService _service;

  ProProfileRepository({ProProfileService? service})
      : _service = service ?? ProProfileService();

  Future<ProProfileModel?> fetchCurrent() async {
    try {
      return await _service.fetchCurrent();
    } catch (e) {
      throw ProProfileFailure(e.toString());
    }
  }

  Future<void> updateProfile({
    required String bio,
    String? fullName,
    String? nif,
  }) async {
    try {
      await _service.updateProfile(bio: bio, fullName: fullName, nif: nif);
    } on AuthException catch (e) {
      throw ProProfileFailure(e.message);
    } catch (e) {
      throw ProProfileFailure(e.toString());
    }
  }

  Future<String> uploadAvatar({required File file}) async {
    try {
      return await _service.uploadAvatar(file: file);
    } on AuthException catch (e) {
      throw ProProfileFailure(e.message);
    } catch (e) {
      throw ProProfileFailure(e.toString());
    }
  }

  Future<String?> getSignedAvatarUrl(String path) async {
    return await _service.getSignedAvatarUrl(path);
  }
}
