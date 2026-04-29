import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';

class ProfileFailure implements Exception {
  final String message;
  const ProfileFailure(this.message);

  @override
  String toString() => message;
}

class ProfileRepository {
  final ProfileService _service;

  ProfileRepository({ProfileService? service})
      : _service = service ?? ProfileService();

  Future<ProfileModel?> fetchCurrent() async {
    try {
      return await _service.fetchCurrent();
    } catch (e) {
      throw ProfileFailure(e.toString());
    }
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required List<String> addresses,
  }) async {
    try {
      await _service.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        addresses: addresses,
      );
    } on AuthException catch (e) {
      throw ProfileFailure(e.message);
    } catch (e) {
      throw ProfileFailure(e.toString());
    }
  }

  Future<String> uploadAvatar({required File file}) async {
    try {
      return await _service.uploadAvatar(file: file);
    } on AuthException catch (e) {
      throw ProfileFailure(e.message);
    } catch (e) {
      throw ProfileFailure(e.toString());
    }
  }

  Future<String?> getSignedAvatarUrl(String path) async {
    return await _service.getSignedAvatarUrl(path);
  }
}
