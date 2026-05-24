import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/profile/controllers/work_settings_controller.dart';
import 'package:project/features/pro/profile/data/models/availability_schedule_model.dart';
import 'package:project/features/pro/profile/data/repositories/work_settings_repository.dart';

// ── Fake repository ────────────────────────────────────────────────────────────

class _FakeWorkSettingsRepository extends WorkSettingsRepository {
  _FakeWorkSettingsRepository({
    List<AvailabilityScheduleModel>? schedules,
    int? radiusKm,
    Future<void> Function(List<AvailabilityScheduleModel>)? onSaveSchedules,
    Future<void> Function(int)? onSaveRadius,
    Future<void> Function(double, double)? onSaveLocation,
  })  : _schedules = schedules ?? const [],
        _radiusKm = radiusKm,
        _onSaveSchedules = onSaveSchedules,
        _onSaveRadius = onSaveRadius,
        _onSaveLocation = onSaveLocation;

  List<AvailabilityScheduleModel> _schedules;
  final int? _radiusKm;
  final Future<void> Function(List<AvailabilityScheduleModel>)? _onSaveSchedules;
  final Future<void> Function(int)? _onSaveRadius;
  final Future<void> Function(double, double)? _onSaveLocation;

  @override
  Future<List<AvailabilityScheduleModel>> fetchSchedules() async => _schedules;

  @override
  Future<int?> fetchServiceRadius() async => _radiusKm;

  @override
  Future<void> saveSchedules(List<AvailabilityScheduleModel> schedules) async {
    await _onSaveSchedules?.call(schedules);
    _schedules = schedules;
  }

  @override
  Future<void> saveServiceRadius(int radiusKm) async =>
      _onSaveRadius?.call(radiusKm);

  @override
  Future<void> saveLocation(
          {required double latitude, required double longitude}) async =>
      _onSaveLocation?.call(latitude, longitude);
}

// ── Test data ─────────────────────────────────────────────────────────────────

AvailabilityScheduleModel _slot({
  String id = '',
  int day = 0,
  int startH = 9,
  int endH = 17,
}) {
  return AvailabilityScheduleModel(
    id: id,
    proId: 'pro-1',
    dayOfWeek: day,
    startTime: TimeOfDay(hour: startH, minute: 0),
    endTime: TimeOfDay(hour: endH, minute: 0),
  );
}

WorkSettingsController _makeController({
  List<AvailabilityScheduleModel>? schedules,
  int? radiusKm,
  Future<void> Function(List<AvailabilityScheduleModel>)? onSaveSchedules,
  Future<void> Function(int)? onSaveRadius,
  Future<void> Function(double, double)? onSaveLocation,
}) {
  return WorkSettingsController(
    repository: _FakeWorkSettingsRepository(
      schedules: schedules,
      radiusKm: radiusKm,
      onSaveSchedules: onSaveSchedules,
      onSaveRadius: onSaveRadius,
      onSaveLocation: onSaveLocation,
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('WorkSettingsController', () {
    group('initial load', () {
      test('loads schedules and radius from repository', () async {
        final controller = _makeController(
          schedules: [_slot(day: 0)],
          radiusKm: 40,
        );
        await Future<void>.delayed(Duration.zero);

        expect(controller.isLoading, isFalse);
        expect(controller.schedules.length, 1);
        expect(controller.radiusKm, 40);
      });

      test('uses default radius 25 when repository returns null', () async {
        final controller = _makeController(radiusKm: null);
        await Future<void>.delayed(Duration.zero);

        expect(controller.radiusKm, 25);
      });
    });

    group('setWorkHours', () {
      test('correctly saves selected availability schedule', () async {
        List<AvailabilityScheduleModel>? captured;
        final controller = _makeController(
          onSaveSchedules: (s) async => captured = s,
        );
        await Future<void>.delayed(Duration.zero);

        final slots = [_slot(day: 0), _slot(day: 1)];
        await controller.setWorkHours(slots);

        expect(controller.saved, isTrue);
        expect(controller.error, isNull);
        expect(captured, slots);
        expect(controller.schedules.length, 2);
      });

      test('sets isSaving to true then false during save', () async {
        final states = <bool>[];
        final controller = _makeController(onSaveSchedules: (_) async {});
        controller.addListener(() => states.add(controller.isSaving));

        await controller.setWorkHours([_slot()]);

        expect(states.first, isTrue);
        expect(states.last, isFalse);
      });

      test('stores error on repository failure', () async {
        final controller = WorkSettingsController(
          repository: _FakeWorkSettingsRepository(
            onSaveSchedules: (_) async => throw Exception('Network error'),
          ),
        );
        await controller.setWorkHours([_slot()]);

        expect(controller.error, isNotNull);
        expect(controller.saved, isFalse);
        expect(controller.isSaving, isFalse);
      });

      test('does not save and sets error on invalid slot', () async {
        bool saveCalled = false;
        final controller = _makeController(
          onSaveSchedules: (_) async => saveCalled = true,
        );
        await Future<void>.delayed(Duration.zero);

        // Invalid: end before start
        final badSlot = _slot(startH: 17, endH: 9);
        await controller.setWorkHours([badSlot]);

        expect(saveCalled, isFalse);
        expect(controller.error, isNotNull);
        expect(controller.saved, isFalse);
      });

      test('does not save and sets error on overlapping slots', () async {
        bool saveCalled = false;
        final controller = _makeController(
          onSaveSchedules: (_) async => saveCalled = true,
        );
        await Future<void>.delayed(Duration.zero);

        final slots = [
          _slot(id: 'a', day: 0, startH: 9, endH: 13),
          _slot(id: 'b', day: 0, startH: 12, endH: 17),
        ];
        await controller.setWorkHours(slots);

        expect(saveCalled, isFalse);
        expect(controller.error, isNotNull);
        expect(controller.saved, isFalse);
      });

      test('saves empty list to clear all schedules', () async {
        List<AvailabilityScheduleModel>? captured;
        final controller = _makeController(
          schedules: [_slot()],
          onSaveSchedules: (s) async => captured = s,
        );
        await Future<void>.delayed(Duration.zero);

        await controller.setWorkHours([]);

        expect(captured, isEmpty);
        expect(controller.saved, isTrue);
      });
    });

    group('setServiceRadius', () {
      test('stores radius value and updates matching criteria', () async {
        int? captured;
        final controller = _makeController(
          onSaveRadius: (r) async => captured = r,
        );
        await Future<void>.delayed(Duration.zero);

        await controller.setServiceRadius(75);

        expect(controller.radiusKm, 75);
        expect(captured, 75);
        expect(controller.saved, isTrue);
        expect(controller.error, isNull);
      });

      test('sets error when radius is zero or negative', () async {
        bool saveCalled = false;
        final controller = _makeController(
          onSaveRadius: (_) async => saveCalled = true,
        );

        await controller.setServiceRadius(0);

        expect(saveCalled, isFalse);
        expect(controller.error, isNotNull);
        expect(controller.saved, isFalse);
      });

      test('sets isSaving to true then false', () async {
        final states = <bool>[];
        final controller = _makeController(onSaveRadius: (_) async {});
        controller.addListener(() => states.add(controller.isSaving));

        await controller.setServiceRadius(30);

        expect(states.first, isTrue);
        expect(states.last, isFalse);
      });

      test('stores error on repository failure', () async {
        final controller = WorkSettingsController(
          repository: _FakeWorkSettingsRepository(
            onSaveRadius: (_) async => throw Exception('Save failed'),
          ),
        );

        await controller.setServiceRadius(30);

        expect(controller.error, isNotNull);
        expect(controller.saved, isFalse);
      });
    });

    group('setLocation', () {
      test('validates and saves selected base location', () async {
        double? capturedLat;
        double? capturedLng;
        final controller = _makeController(
          onSaveLocation: (lat, lng) async {
            capturedLat = lat;
            capturedLng = lng;
          },
        );
        await Future<void>.delayed(Duration.zero);

        await controller.setLocation(latitude: 41.15, longitude: -8.63);

        expect(controller.latitude, 41.15);
        expect(controller.longitude, -8.63);
        expect(capturedLat, 41.15);
        expect(capturedLng, -8.63);
        expect(controller.saved, isTrue);
        expect(controller.error, isNull);
      });

      test('rejects invalid latitude above 90', () async {
        bool saveCalled = false;
        final controller = _makeController(
          onSaveLocation: (lat, lng) async => saveCalled = true,
        );

        await controller.setLocation(latitude: 91, longitude: 0);

        expect(saveCalled, isFalse);
        expect(controller.error, isNotNull);
        expect(controller.saved, isFalse);
      });

      test('rejects invalid latitude below -90', () async {
        bool saveCalled = false;
        final controller = _makeController(
          onSaveLocation: (lat, lng) async => saveCalled = true,
        );

        await controller.setLocation(latitude: -91, longitude: 0);

        expect(saveCalled, isFalse);
        expect(controller.error, isNotNull);
      });

      test('rejects invalid longitude outside -180..180', () async {
        bool saveCalled = false;
        final controller = _makeController(
          onSaveLocation: (lat, lng) async => saveCalled = true,
        );

        await controller.setLocation(latitude: 0, longitude: 181);

        expect(saveCalled, isFalse);
        expect(controller.error, isNotNull);
      });

      test('stores error on repository failure', () async {
        final controller = WorkSettingsController(
          repository: _FakeWorkSettingsRepository(
            onSaveLocation: (lat, lng) async => throw Exception('Save failed'),
          ),
        );

        await controller.setLocation(latitude: 41.15, longitude: -8.63);

        expect(controller.error, isNotNull);
        expect(controller.saved, isFalse);
      });

      test('sets isSaving to true then false', () async {
        final states = <bool>[];
        final controller = _makeController(
          onSaveLocation: (lat, lng) async {},
        );
        controller.addListener(() => states.add(controller.isSaving));

        await controller.setLocation(latitude: 41.15, longitude: -8.63);

        expect(states.first, isTrue);
        expect(states.last, isFalse);
      });
    });

    group('validateAvailability', () {
      test('returns null for valid non-overlapping slots', () {
        final controller = _makeController();
        final slots = [
          _slot(id: 'a', day: 0, startH: 9, endH: 12),
          _slot(id: 'b', day: 0, startH: 13, endH: 17),
          _slot(id: 'c', day: 1, startH: 9, endH: 17),
        ];
        expect(controller.validateAvailability(slots), isNull);
      });

      test('rejects overlapping time slots on same day', () {
        final controller = _makeController();
        final slots = [
          _slot(id: 'a', day: 0, startH: 9, endH: 13),
          _slot(id: 'b', day: 0, startH: 12, endH: 17),
        ];
        expect(controller.validateAvailability(slots), isNotNull);
      });

      test('rejects invalid time slot where end is before start', () {
        final controller = _makeController();
        expect(
          controller.validateAvailability([_slot(startH: 17, endH: 9)]),
          isNotNull,
        );
      });

      test('rejects slot where start equals end', () {
        final controller = _makeController();
        final slot = AvailabilityScheduleModel(
          id: '',
          proId: 'pro-1',
          dayOfWeek: 0,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 9, minute: 0),
        );
        expect(controller.validateAvailability([slot]), isNotNull);
      });

      test('returns null for empty list', () {
        expect(_makeController().validateAvailability([]), isNull);
      });

      test('allows same time range on different days', () {
        final controller = _makeController();
        final slots = [
          _slot(id: 'a', day: 0, startH: 9, endH: 17),
          _slot(id: 'b', day: 1, startH: 9, endH: 17),
        ];
        expect(controller.validateAvailability(slots), isNull);
      });
    });

    group('clearError and clearSaved', () {
      test('clearError resets the error state', () async {
        final controller = WorkSettingsController(
          repository: _FakeWorkSettingsRepository(
            onSaveRadius: (_) async => throw Exception('boom'),
          ),
        );

        await controller.setServiceRadius(30);
        expect(controller.error, isNotNull);

        controller.clearError();
        expect(controller.error, isNull);
      });

      test('clearSaved resets the saved state', () async {
        final controller = _makeController(onSaveRadius: (_) async {});

        await controller.setServiceRadius(30);
        expect(controller.saved, isTrue);

        controller.clearSaved();
        expect(controller.saved, isFalse);
      });
    });

    test('notifyListeners is called at least twice during setWorkHours',
        () async {
      int count = 0;
      final controller = _makeController(onSaveSchedules: (_) async {});
      controller.addListener(() => count++);

      await controller.setWorkHours([_slot()]);

      expect(count, greaterThanOrEqualTo(2));
    });
  });
}
