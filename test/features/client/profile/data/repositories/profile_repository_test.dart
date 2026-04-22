import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project/features/client/profile/data/models/profile_model.dart';
import 'package:project/features/client/profile/data/repositories/profile_repository.dart';
import 'package:project/features/client/profile/data/services/profile_service.dart';

class _FakeProfileService extends ProfileService {
  _FakeProfileService({this.profile, this.onUpdate});

  final ProfileModel? profile;
  final Future<void> Function()? onUpdate;

  @override
  ProfileModel? fetchCurrent() => profile;

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
  group('ProfileRepository', () {
    test('fetchCurrent returns the profile from the service', () {
      final repo = ProfileRepository(
        service: _FakeProfileService(profile: _profile),
      );

      expect(repo.fetchCurrent()?.fullName, 'Bruno Silva');
    });

    test('fetchCurrent returns null when service returns null', () {
      final repo = ProfileRepository(
        service: _FakeProfileService(profile: null),
      );

      expect(repo.fetchCurrent(), isNull);
    });

    test('updateProfile completes without error on success', () async {
      final repo = ProfileRepository(
        service: _FakeProfileService(onUpdate: () async {}),
      );

      await expectLater(
        repo.updateProfile(
          firstName: 'Ana',
          lastName: 'Costa',
          phone: '912111222',
          addresses: [],
        ),
        completes,
      );
    });

    test('updateProfile wraps AuthException in ProfileFailure', () async {
      final repo = ProfileRepository(
        service: _FakeProfileService(
          onUpdate: () async => throw const AuthException('Not authenticated'),
        ),
      );

      await expectLater(
        () => repo.updateProfile(
          firstName: 'Ana',
          lastName: 'Costa',
          phone: '912111222',
          addresses: [],
        ),
        throwsA(
          isA<ProfileFailure>().having(
            (e) => e.message,
            'message',
            'Not authenticated',
          ),
        ),
      );
    });

    test('updateProfile wraps generic exceptions in ProfileFailure', () async {
      final repo = ProfileRepository(
        service: _FakeProfileService(
          onUpdate: () async => throw Exception('network error'),
        ),
      );

      await expectLater(
        () => repo.updateProfile(
          firstName: 'Ana',
          lastName: 'Costa',
          phone: '912111222',
          addresses: [],
        ),
        throwsA(isA<ProfileFailure>()),
      );
    });
  });
}
