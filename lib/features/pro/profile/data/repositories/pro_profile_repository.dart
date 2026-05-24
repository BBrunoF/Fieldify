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
    required int? serviceRadiusKm,
    String? fullName,
    String? nif,
    List<String>? credentialUrls,
  }) async {
    try {
      await _service.updateProfile(
        bio: bio,
        serviceRadiusKm: serviceRadiusKm,
        fullName: fullName,
        nif: nif,
        credentialUrls: credentialUrls,
      );
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

  Future<String> uploadCredential({
    required File file,
    required String filename,
  }) async {
    try {
      return await _service.uploadCredential(file: file, filename: filename);
    } on AuthException catch (e) {
      throw ProProfileFailure(e.message);
    } catch (e) {
      throw ProProfileFailure(e.toString());
    }
  }

  Future<void> deleteCredential(String path) async {
    try {
      await _service.deleteCredential(path);
    } on AuthException catch (e) {
      throw ProProfileFailure(e.message);
    } catch (e) {
      throw ProProfileFailure(e.toString());
    }
  }

  Future<String?> getSignedCredentialUrl(String path) async {
    return await _service.getSignedCredentialUrl(path);
  }

  Future<List<ProReview>> fetchProviderReviews(String proId) async {
    try {
      return await _service.fetchProviderReviews(proId);
    } on PostgrestException catch (e) {
      throw ProProfileFailure(e.message);
    } catch (e) {
      throw ProProfileFailure(e.toString());
    }
  }

  Future<ProRatingSummary> getProviderRating(String proId) async {
    try {
      return await _service.getProviderRating(proId);
    } on PostgrestException catch (e) {
      throw ProProfileFailure(e.message);
    } catch (e) {
      throw ProProfileFailure(e.toString());
    }
  }

  Future<List<ProReview>> fetchCurrentReviews() async {
    try {
      return await _service.fetchCurrentReviews();
    } on PostgrestException catch (e) {
      throw ProProfileFailure(e.message);
    } catch (e) {
      throw ProProfileFailure(e.toString());
    }
  }

  Future<String> connectStripe() async {
    try {
      return await _service.createConnectAccount();
    } on AuthException catch (e) {
      throw ProProfileFailure(e.message);
    } catch (e) {
      throw ProProfileFailure(e.toString());
    }
  }
}
