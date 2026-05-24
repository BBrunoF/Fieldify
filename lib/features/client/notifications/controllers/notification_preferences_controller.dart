import 'package:flutter/foundation.dart';
import '../data/repositories/notification_repository.dart';

class NotificationPreferencesController extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationPreferencesController({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository();

  bool _isGranted = false;
  bool _isLoading = false;
  String? _error;

  bool get isGranted => _isGranted;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> requestNotificationPermission() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _isGranted = await _repository.requestPermission();
      return _isGranted;
    } on NotificationFailure catch (e) {
      _error = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateNotificationPreferences({required bool enabled}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.updatePreferences(enabled: enabled);
      _isGranted = enabled;
    } on NotificationFailure catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
