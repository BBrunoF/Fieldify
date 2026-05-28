import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/availability_schedule_model.dart';
import '../services/work_settings_service.dart';

class WorkSettingsFailure implements Exception {
  final String message;
  const WorkSettingsFailure(this.message);

  @override
  String toString() => message;
}

class WorkSettingsRepository {
  final WorkSettingsService _service;

  WorkSettingsRepository({WorkSettingsService? service})
      : _service = service ?? WorkSettingsService();

  Future<List<AvailabilityScheduleModel>> fetchSchedules() async {
    try {
      return await _service.fetchSchedules();
    } catch (e) {
      throw WorkSettingsFailure(e.toString());
    }
  }

  Future<int?> fetchServiceRadius() async {
    try {
      return await _service.fetchServiceRadius();
    } catch (e) {
      throw WorkSettingsFailure(e.toString());
    }
  }

  Future<void> saveSchedules(List<AvailabilityScheduleModel> schedules) async {
    try {
      await _service.saveSchedules(schedules);
    } on AuthException catch (e) {
      throw WorkSettingsFailure(e.message);
    } catch (e) {
      throw WorkSettingsFailure(e.toString());
    }
  }

  Future<void> saveServiceRadius(int radiusKm) async {
    try {
      await _service.saveServiceRadius(radiusKm);
    } on AuthException catch (e) {
      throw WorkSettingsFailure(e.message);
    } catch (e) {
      throw WorkSettingsFailure(e.toString());
    }
  }

  Future<({double lat, double lng})?> fetchLocation() async {
    try {
      return await _service.fetchLocation();
    } catch (e) {
      throw WorkSettingsFailure(e.toString());
    }
  }

  Future<void> saveLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _service.saveLocation(latitude: latitude, longitude: longitude);
    } on AuthException catch (e) {
      throw WorkSettingsFailure(e.message);
    } catch (e) {
      throw WorkSettingsFailure(e.toString());
    }
  }
}
