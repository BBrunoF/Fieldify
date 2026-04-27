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
  bool _isSaving = false;
  bool _isLoading = true;
  String? _error;
  bool _saved = false;

  ProfileModel? get profile => _profile;
  bool get isSaving => _isSaving;
  bool get isLoading => _isLoading;
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

  void clearSaved() {
    _saved = false;
    notifyListeners();
  }
}
