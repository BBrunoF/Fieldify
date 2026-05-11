import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project/features/client/profile/data/models/profile_model.dart';
import 'package:project/features/client/profile/data/repositories/profile_repository.dart';
import 'package:project/features/client/profile/data/services/profile_service.dart';

class _FakeProfileService extends ProfileService {
  _FakeProfileService({
    this.profile,
    this.onUpdate,
    this.onUpload,
    this.throwOn,
  });

  final ProfileModel? profile;
  final Future<void> Function()? onUpdate;
  final Future<String> Function()? onUpload;
  final Exception? throwOn;

  @override
  Future<ProfileModel?> fetchCurrent() async => profile;

  @override
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required List<String> addresses,
  }) async {
    if (throwOn != null) throw throwOn!;
    await onUpdate?.call();
  }

  @override
  Future<String> uploadAvatar({required File file}) async {
    if (throwOn != null) throw throwOn!;
    if (onUpload != null) return onUpload!();
    return 'uid/avatar.jpg';
  }

  @override
  Future<String?> getSignedAvatarUrl(String path) async => null;
}

const _profile = ProfileModel(
  fullName: 'Bruno Silva',
  phone: '912000000',
  email: 'bruno@example.com',
  addresses: [],
);

void main() {
  group('ProfileRepository', () {
    test('fetchCurrent returns the profile from the service', () async {
      final repo = ProfileRepository(
        service: _FakeProfileService(profile: _profile),
      );

      expect((await repo.fetchCurrent())?.fullName, 'Bruno Silva');
    });

    test('fetchCurrent returns null when service returns null', () async {
      final repo = ProfileRepository(
        service: _FakeProfileService(profile: null),
      );

      expect(await repo.fetchCurrent(), isNull);
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

    test('uploadAvatar returns path on success', () async {
      final repo = ProfileRepository(
        service: _FakeProfileService(
          onUpload: () async => 'uid/avatar.jpg',
        ),
      );

      final path = await repo.uploadAvatar(file: File('fake.jpg'));
      expect(path, 'uid/avatar.jpg');
    });

    test('uploadAvatar wraps AuthException in ProfileFailure', () async {
      final repo = ProfileRepository(
        service: _FakeProfileService(
          throwOn: const AuthException('Not authenticated'),
        ),
      );

      await expectLater(
        () => repo.uploadAvatar(file: File('fake.jpg')),
        throwsA(
          isA<ProfileFailure>().having(
            (e) => e.message,
            'message',
            'Not authenticated',
          ),
        ),
      );
    });

    test('uploadAvatar wraps generic exceptions in ProfileFailure', () async {
      final repo = ProfileRepository(
        service: _FakeProfileService(
          throwOn: Exception('storage error'),
        ),
      );

      await expectLater(
        () => repo.uploadAvatar(file: File('fake.jpg')),
        throwsA(isA<ProfileFailure>()),
      );
    });

    test('getSignedAvatarUrl returns null when service returns null', () async {
      final repo = ProfileRepository(service: _FakeProfileService());
      expect(await repo.getSignedAvatarUrl('uid/avatar.jpg'), isNull);
    });
  });
}
