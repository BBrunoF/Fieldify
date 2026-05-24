import 'package:flutter/foundation.dart';
import '../data/models/availability_schedule_model.dart';
import '../data/repositories/work_settings_repository.dart';

class WorkSettingsController extends ChangeNotifier {
  final WorkSettingsRepository _repository;

  WorkSettingsController({WorkSettingsRepository? repository})
      : _repository = repository ?? WorkSettingsRepository() {
    _load();
  }

  List<AvailabilityScheduleModel> _schedules = const [];
  int _radiusKm = 25;
  double? _latitude;
  double? _longitude;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  bool _saved = false;

  List<AvailabilityScheduleModel> get schedules => _schedules;
  int get radiusKm => _radiusKm;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  bool get saved => _saved;

  Future<void> _load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _schedules = await _repository.fetchSchedules();
      final radius = await _repository.fetchServiceRadius();
      if (radius != null) _radiusKm = radius;
    } catch (e) {
      debugPrint('WorkSettingsController: failed to load work settings: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  String? validateAvailability(List<AvailabilityScheduleModel> schedules) {
    for (final s in schedules) {
      if (!s.isValid) return 'End time must be after start time';
    }
    for (int i = 0; i < schedules.length; i++) {
      for (int j = i + 1; j < schedules.length; j++) {
        if (schedules[i].overlaps(schedules[j])) {
          return 'Time slots cannot overlap';
        }
      }
    }
    return null;
  }

  Future<void> setWorkHours(List<AvailabilityScheduleModel> schedules) async {
    final validationError = validateAvailability(schedules);
    if (validationError != null) {
      _error = validationError;
      notifyListeners();
      return;
    }

    _isSaving = true;
    _error = null;
    _saved = false;
    notifyListeners();

    try {
      await _repository.saveSchedules(schedules);
      _schedules = List.unmodifiable(schedules);
      _saved = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> setServiceRadius(int radiusKm) async {
    if (radiusKm <= 0) {
      _error = 'Radius must be greater than 0';
      notifyListeners();
      return;
    }

    _isSaving = true;
    _error = null;
    _saved = false;
    notifyListeners();

    try {
      await _repository.saveServiceRadius(radiusKm);
      _radiusKm = radiusKm;
      _saved = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> setLocation({
    required double latitude,
    required double longitude,
  }) async {
    if (latitude < -90 || latitude > 90) {
      _error = 'Latitude must be between -90 and 90';
      notifyListeners();
      return;
    }
    if (longitude < -180 || longitude > 180) {
      _error = 'Longitude must be between -180 and 180';
      notifyListeners();
      return;
    }

    _isSaving = true;
    _error = null;
    _saved = false;
    notifyListeners();

    try {
      await _repository.saveLocation(latitude: latitude, longitude: longitude);
      _latitude = latitude;
      _longitude = longitude;
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
