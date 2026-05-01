import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/models/profile_model.dart';
import '../data/repositories/profile_repository.dart';

class ProfileController extends ChangeNotifier {
  final ProfileRepository _repository;

  ProfileController({ProfileRepository? repository})
      : _repository = repository ?? ProfileRepository() {
    _load();
  }

  ProfileModel? _profile;
  String? _avatarSignedUrl;
  bool _isSaving = false;
  bool _isLoading = true;
  bool _isUploadingAvatar = false;
  String? _error;
  bool _saved = false;

  ProfileModel? get profile => _profile;
  String? get avatarSignedUrl => _avatarSignedUrl;
  bool get isSaving => _isSaving;
  bool get isLoading => _isLoading;
  bool get isUploadingAvatar => _isUploadingAvatar;
  String? get error => _error;
  bool get saved => _saved;

  Future<void> _load() async {
    _isLoading = true;
    try {
      _profile = await _repository.fetchCurrent();
    } catch (_) {
      // profile stays null
    }
    _isLoading = false;
    notifyListeners();
    if (_profile?.avatarPath != null) {
      _repository.getSignedAvatarUrl(_profile!.avatarPath!).then((url) {
        _avatarSignedUrl = url;
        notifyListeners();
      }).ignore();
    }
  }

  Future<void> saveAll({
    required String firstName,
    required String lastName,
    required String phone,
    required List<String> addresses,
  }) async {
    _isSaving = true;
    _error = null;
    _saved = false;
    notifyListeners();

    try {
      await _repository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        addresses: addresses,
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

  void clearError() {
    _error = null;
    notifyListeners();
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

  void clearSaved() {
    _saved = false;
    notifyListeners();
  }
}
