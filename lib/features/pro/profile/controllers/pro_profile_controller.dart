import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isUploadingCredential = false;
  String? _error;
  bool _saved = false;
  List<ProReview> _reviews = const [];
  ProRatingSummary _ratingSummary = ProRatingSummary.empty;
  bool _isLoadingReviews = false;
  bool _isConnectingStripe = false;

  ProProfileModel? get profile => _profile;
  String? get avatarSignedUrl => _avatarSignedUrl;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isUploadingAvatar => _isUploadingAvatar;
  bool get isUploadingCredential => _isUploadingCredential;
  String? get error => _error;
  bool get saved => _saved;
  List<ProReview> get reviews => _reviews;
  ProRatingSummary get ratingSummary => _ratingSummary;
  bool get isLoadingReviews => _isLoadingReviews;
  bool get isConnectingStripe => _isConnectingStripe;

  Future<void> _load() async {
    _isLoading = true;
    try {
      _profile = await _repository.fetchCurrent();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
    if (_profile?.avatarPath != null) {
      _repository.getSignedAvatarUrl(_profile!.avatarPath!).then((url) {
        _avatarSignedUrl = url;
        notifyListeners();
      }).ignore();
    }
    if (_profile != null) {
      loadReviews().ignore();
    }
  }

  Future<void> loadReviews() async {
    _isLoadingReviews = true;
    notifyListeners();
    try {
      _reviews = await _repository.fetchCurrentReviews();
      _ratingSummary = ProRatingSummary.fromReviews(_reviews);
    } catch (_) {
      _reviews = const [];
      _ratingSummary = ProRatingSummary.empty;
    } finally {
      _isLoadingReviews = false;
      notifyListeners();
    }
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

  /// Uploads a credential file to storage and returns its path, or null on
  /// failure (with [error] set). The caller adds the returned path to the
  /// credential list and persists it via [saveProfile].
  Future<String?> uploadCredential(File file, {required String filename}) async {
    _isUploadingCredential = true;
    _error = null;
    notifyListeners();

    try {
      return await _repository.uploadCredential(file: file, filename: filename);
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isUploadingCredential = false;
      notifyListeners();
    }
  }

  Future<void> deleteCredential(String path) async {
    try {
      await _repository.deleteCredential(path);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<String?> getSignedCredentialUrl(String path) =>
      _repository.getSignedCredentialUrl(path);

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSaved() {
    _saved = false;
    notifyListeners();
  }

  Future<void> connectStripe() async {
    _isConnectingStripe = true;
    _error = null;
    notifyListeners();

    try {
      final url = await _repository.connectStripe();
      // TEMP: copy this from the console and open in desktop Chrome to rule
      // out emulator/browser flakiness during Stripe onboarding.
      debugPrint('STRIPE ONBOARDING URL: $url');
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _error = 'Could not open Stripe onboarding page';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isConnectingStripe = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    try {
      _profile = await _repository.fetchCurrent();
      notifyListeners();
    } catch (_) {}
  }
}
