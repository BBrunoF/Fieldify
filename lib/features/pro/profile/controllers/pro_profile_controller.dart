import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/models/pro_profile_model.dart';
import '../data/repositories/pro_profile_repository.dart';

class ProProfileController extends ChangeNotifier {
  final ProProfileRepository _repository;

  ProProfileController({ProProfileRepository? repository})
      : _repository = repository ?? ProProfileRepository() {
    _load();
  }

  ProProfileModel? _profile;
  String? _avatarSignedUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _error;
  bool _saved = false;

  ProProfileModel? get profile => _profile;
  String? get avatarSignedUrl => _avatarSignedUrl;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isUploadingAvatar => _isUploadingAvatar;
  String? get error => _error;
  bool get saved => _saved;

  Future<void> _load() async {
    _isLoading = true;
    try {
      _profile = await _repository.fetchCurrent();
      if (_profile?.avatarPath != null) {
        _avatarSignedUrl =
            await _repository.getSignedAvatarUrl(_profile!.avatarPath!);
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveProfile({
    required String bio,
    required String firstName,
    required String lastName,
    required String nif,
    required int? serviceRadiusKm,
    List<String>? credentialUrls,
  }) async {
    _isSaving = true;
    _error = null;
    _saved = false;
    notifyListeners();

    try {
      final fullName = '${firstName.trim()} ${lastName.trim()}';
      await _repository.updateProfile(
        bio: bio,
        serviceRadiusKm: serviceRadiusKm,
        fullName: _profile?.isApproved == true ? null : fullName,
        nif: _profile?.isApproved == true ? null : nif,
        credentialUrls: _profile?.isApproved == true ? null : credentialUrls,
      );
      _profile = await _repository.fetchCurrent();
      _saved = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> uploadAvatar(File file) async {
    _isUploadingAvatar = true;
    _error = null;
    notifyListeners();

    try {
      final path = await _repository.uploadAvatar(file: file);
      _profile = _profile?.copyWith(avatarPath: path);
      _avatarSignedUrl = await _repository.getSignedAvatarUrl(path);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isUploadingAvatar = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSaved() {
    _saved = false;
    notifyListeners();
  }
}
