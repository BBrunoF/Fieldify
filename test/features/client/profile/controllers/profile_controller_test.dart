import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/client/profile/controllers/profile_controller.dart';
import 'package:project/features/client/profile/data/models/profile_model.dart';
import 'package:project/features/client/profile/data/repositories/profile_repository.dart';

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository({this.profile, this.onUpdate});

  final ProfileModel? profile;
  final Future<void> Function()? onUpdate;

  @override
  Future<ProfileModel?> fetchCurrent() async => profile;

  @override
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required List<String> addresses,
  }) async {
    await onUpdate?.call();
  }
}

const _profile = ProfileModel(
  fullName: 'Bruno Silva',
  phone: '912000000',
  email: 'bruno@example.com',
  addresses: [],
);

void main() {
  group('ProfileController', () {
    test('profile is loaded from repository on construction', () async {
      final controller = ProfileController(
        repository: _FakeProfileRepository(profile: _profile),
      );

      await Future<void>.delayed(Duration.zero); // let async _load() complete
      expect(controller.profile?.fullName, 'Bruno Silva');
      expect(controller.isSaving, isFalse);
      expect(controller.error, isNull);
      expect(controller.saved, isFalse);
    });

    test('profile is null when repository returns null', () async {
      final controller = ProfileController(
        repository: _FakeProfileRepository(profile: null),
      );

      await Future<void>.delayed(Duration.zero);
      expect(controller.profile, isNull);
    });

    test('saveAll sets isSaving to true then false', () async {
      final savingStates = <bool>[];

      final controller = ProfileController(
        repository: _FakeProfileRepository(
          onUpdate: () async {},
        ),
      );

      controller.addListener(() {
        savingStates.add(controller.isSaving);
      });

      await controller.saveAll(
        firstName: 'Ana',
        lastName: 'Costa',
        phone: '912111222',
        addresses: [],
      );

      expect(savingStates.first, isTrue);
      expect(savingStates.last, isFalse);
    });

    test('saveAll on success sets saved=true and clears error', () async {
      final controller = ProfileController(
        repository: _FakeProfileRepository(
          profile: _profile,
          onUpdate: () async {},
        ),
      );

      await controller.saveAll(
        firstName: 'Ana',
        lastName: 'Costa',
        phone: '912111222',
        addresses: [],
      );

      expect(controller.saved, isTrue);
      expect(controller.error, isNull);
      expect(controller.isSaving, isFalse);
    });

    test('saveAll on failure stores error message and clears saved', () async {
      final controller = ProfileController(
        repository: _FakeProfileRepository(
          onUpdate: () async => throw Exception('Network error'),
        ),
      );

      await controller.saveAll(
        firstName: 'Ana',
        lastName: 'Costa',
        phone: '912111222',
        addresses: [],
      );

      expect(controller.error, isNotNull);
      expect(controller.saved, isFalse);
      expect(controller.isSaving, isFalse);
    });

    test('clearError resets the error state', () async {
      final controller = ProfileController(
        repository: _FakeProfileRepository(
          onUpdate: () async => throw Exception('boom'),
        ),
      );

      await controller.saveAll(
        firstName: 'Ana',
        lastName: 'Costa',
        phone: '912111222',
        addresses: [],
      );

      expect(controller.error, isNotNull);
      controller.clearError();
      expect(controller.error, isNull);
    });

    test('clearSaved resets the saved state', () async {
      final controller = ProfileController(
        repository: _FakeProfileRepository(
          onUpdate: () async {},
        ),
      );

      await controller.saveAll(
        firstName: 'Ana',
        lastName: 'Costa',
        phone: '912111222',
        addresses: [],
      );

      expect(controller.saved, isTrue);
      controller.clearSaved();
      expect(controller.saved, isFalse);
    });

    test('notifyListeners is called on saveAll completion', () async {
      int notifyCount = 0;

      final controller = ProfileController(
        repository: _FakeProfileRepository(onUpdate: () async {}),
      );

      controller.addListener(() => notifyCount++);

      await controller.saveAll(
        firstName: 'Ana',
        lastName: 'Costa',
        phone: '912111222',
        addresses: [],
      );

      expect(notifyCount, greaterThanOrEqualTo(2));
    });
  });
}
