import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/profile/data/models/availability_schedule_model.dart';
import 'package:project/features/pro/profile/data/repositories/work_settings_repository.dart';
import 'package:project/features/pro/profile/data/services/work_settings_service.dart';

// ── Fake service ───────────────────────────────────────────────────────────────

class _FakeWorkSettingsService extends WorkSettingsService {
  final List<AvailabilityScheduleModel> schedules;
  final int? radiusKm;
  final Future<void> Function()? onSaveSchedules;
  final Future<void> Function(int)? onSaveRadius;
  final Future<void> Function(double, double)? onSaveLocation;

  _FakeWorkSettingsService({
    this.schedules = const [],
    this.radiusKm,
    this.onSaveSchedules,
    this.onSaveRadius,
    this.onSaveLocation,
  });

  @override
  Future<List<AvailabilityScheduleModel>> fetchSchedules() async => schedules;

  @override
  Future<int?> fetchServiceRadius() async => radiusKm;

  @override
  Future<void> saveSchedules(List<AvailabilityScheduleModel> s) async =>
      onSaveSchedules?.call();

  @override
  Future<void> saveServiceRadius(int r) async => onSaveRadius?.call(r);

  @override
  Future<void> saveLocation(
          {required double latitude, required double longitude}) async =>
      onSaveLocation?.call(latitude, longitude);
}

class _ThrowingService extends WorkSettingsService {
  @override
  Future<List<AvailabilityScheduleModel>> fetchSchedules() async =>
      throw Exception('DB error');

  @override
  Future<int?> fetchServiceRadius() async => throw Exception('DB error');

  @override
  Future<void> saveSchedules(List<AvailabilityScheduleModel> s) async =>
      throw Exception('save error');

  @override
  Future<void> saveServiceRadius(int r) async => throw Exception('save error');

  @override
  Future<void> saveLocation(
          {required double latitude, required double longitude}) async =>
      throw Exception('save error');
}

const _schedule = AvailabilityScheduleModel(
  id: 'id-1',
  proId: 'pro-1',
  dayOfWeek: 0,
  startTime: TimeOfDay(hour: 9, minute: 0),
  endTime: TimeOfDay(hour: 17, minute: 0),
);

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('WorkSettingsRepository', () {
    group('fetchSchedules', () {
      test('returns schedules from service', () async {
        final repo = WorkSettingsRepository(
          service: _FakeWorkSettingsService(schedules: [_schedule]),
        );
        final result = await repo.fetchSchedules();
        expect(result, [_schedule]);
      });

      test('wraps service exception as WorkSettingsFailure', () async {
        final repo =
            WorkSettingsRepository(service: _ThrowingService());
        expect(
          () => repo.fetchSchedules(),
          throwsA(isA<WorkSettingsFailure>()),
        );
      });
    });

    group('fetchServiceRadius', () {
      test('returns radius from service', () async {
        final repo = WorkSettingsRepository(
          service: _FakeWorkSettingsService(radiusKm: 30),
        );
        expect(await repo.fetchServiceRadius(), 30);
      });

      test('wraps service exception as WorkSettingsFailure', () async {
        final repo =
            WorkSettingsRepository(service: _ThrowingService());
        expect(
          () => repo.fetchServiceRadius(),
          throwsA(isA<WorkSettingsFailure>()),
        );
      });
    });

    group('saveSchedules', () {
      test('delegates to service without throwing on success', () async {
        bool called = false;
        final repo = WorkSettingsRepository(
          service: _FakeWorkSettingsService(
            onSaveSchedules: () async => called = true,
          ),
        );
        await repo.saveSchedules([_schedule]);
        expect(called, isTrue);
      });

      test('wraps service exception as WorkSettingsFailure', () async {
        final repo =
            WorkSettingsRepository(service: _ThrowingService());
        expect(
          () => repo.saveSchedules([_schedule]),
          throwsA(isA<WorkSettingsFailure>()),
        );
      });
    });

    group('saveServiceRadius', () {
      test('passes radius to service', () async {
        int? captured;
        final repo = WorkSettingsRepository(
          service: _FakeWorkSettingsService(
            onSaveRadius: (r) async => captured = r,
          ),
        );
        await repo.saveServiceRadius(50);
        expect(captured, 50);
      });

      test('wraps service exception as WorkSettingsFailure', () async {
        final repo =
            WorkSettingsRepository(service: _ThrowingService());
        expect(
          () => repo.saveServiceRadius(50),
          throwsA(isA<WorkSettingsFailure>()),
        );
      });
    });

    group('saveLocation', () {
      test('passes coordinates to service', () async {
        double? capturedLat;
        double? capturedLng;
        final repo = WorkSettingsRepository(
          service: _FakeWorkSettingsService(
            onSaveLocation: (lat, lng) async {
              capturedLat = lat;
              capturedLng = lng;
            },
          ),
        );
        await repo.saveLocation(latitude: 41.15, longitude: -8.63);
        expect(capturedLat, 41.15);
        expect(capturedLng, -8.63);
      });

      test('wraps service exception as WorkSettingsFailure', () async {
        final repo =
            WorkSettingsRepository(service: _ThrowingService());
        expect(
          () => repo.saveLocation(latitude: 41.15, longitude: -8.63),
          throwsA(isA<WorkSettingsFailure>()),
        );
      });
    });
  });
}
