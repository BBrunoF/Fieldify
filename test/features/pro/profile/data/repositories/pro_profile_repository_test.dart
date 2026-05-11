import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project/features/pro/profile/data/models/pro_profile_model.dart';
import 'package:project/features/pro/profile/data/repositories/pro_profile_repository.dart';
import 'package:project/features/pro/profile/data/services/pro_profile_service.dart';

class _FakeProProfileService extends ProProfileService {
  _FakeProProfileService({
    this.profile,
    this.onUpdate,
    this.uploadedPath = 'uid/avatar.jpg',
    this.throwOn,
  });

  final ProProfileModel? profile;
  final Future<void> Function()? onUpdate;
  final String uploadedPath;
  final Exception? throwOn;

  @override
  Future<ProProfileModel?> fetchCurrent() async {
    if (throwOn != null) throw throwOn!;
    return profile;
  }

  @override
  Future<void> updateProfile({
    required String bio,
    required int? serviceRadiusKm,
    String? fullName,
    String? nif,
    List<String>? credentialUrls,
  }) async {
    if (throwOn != null) throw throwOn!;
    await onUpdate?.call();
  }

  @override
  Future<String> uploadAvatar({required File file}) async {
    if (throwOn != null) throw throwOn!;
    return uploadedPath;
  }

  @override
  Future<String?> getSignedAvatarUrl(String path) async => null;
}

const _profile = ProProfileModel(
  fullName: 'Bruno Silva',
  nif: '123456789',
  bio: 'Plumber',
  verificationStatus: 'pending',
  avatarPath: null,
  tradeName: 'Plumbing',
  standardRate: 35,
  credentialUrls: ['https://example.com/cert.pdf'],
  serviceRadiusKm: 25,
);

void main() {
  group('ProProfileRepository', () {
    test('fetchCurrent returns the profile from the service', () async {
      final repo = ProProfileRepository(
        service: _FakeProProfileService(profile: _profile),
      );

      final result = await repo.fetchCurrent();
      expect(result?.fullName, 'Bruno Silva');
    });

    test('fetchCurrent returns null when service returns null', () async {
      final repo = ProProfileRepository(
        service: _FakeProProfileService(profile: null),
      );

      expect(await repo.fetchCurrent(), isNull);
    });

    test('fetchCurrent wraps exceptions in ProProfileFailure', () async {
      final repo = ProProfileRepository(
        service: _FakeProProfileService(
          throwOn: Exception('network error'),
        ),
      );

      await expectLater(
        repo.fetchCurrent,
        throwsA(isA<ProProfileFailure>()),
      );
    });

    test('updateProfile completes without error on success', () async {
      final repo = ProProfileRepository(
        service: _FakeProProfileService(onUpdate: () async {}),
      );

      await expectLater(
        repo.updateProfile(bio: 'New bio', serviceRadiusKm: 30),
        completes,
      );
    });

    test('updateProfile passes credentialUrls and serviceRadiusKm', () async {
      List<String>? capturedUrls;
      int? capturedRadius;

      final service = _CapturingService(
        onUpdate: ({
          required bio,
          required serviceRadiusKm,
          fullName,
          nif,
          credentialUrls,
        }) async {
          capturedUrls = credentialUrls;
          capturedRadius = serviceRadiusKm;
        },
      );

      final repo = ProProfileRepository(service: service);
      await repo.updateProfile(
        bio: 'Bio',
        serviceRadiusKm: 40,
        credentialUrls: ['https://example.com/cert.pdf'],
      );

      expect(capturedUrls, ['https://example.com/cert.pdf']);
      expect(capturedRadius, 40);
    });

    test('updateProfile wraps AuthException in ProProfileFailure', () async {
      final repo = ProProfileRepository(
        service: _FakeProProfileService(
          throwOn: const AuthException('Not authenticated'),
        ),
      );

      await expectLater(
        () => repo.updateProfile(bio: 'New bio', serviceRadiusKm: null),
        throwsA(
          isA<ProProfileFailure>().having(
            (e) => e.message,
            'message',
            'Not authenticated',
          ),
        ),
      );
    });

    test('updateProfile wraps generic exceptions in ProProfileFailure',
        () async {
      final repo = ProProfileRepository(
        service: _FakeProProfileService(
          throwOn: Exception('network error'),
        ),
      );

      await expectLater(
        () => repo.updateProfile(bio: 'New bio', serviceRadiusKm: null),
        throwsA(isA<ProProfileFailure>()),
      );
    });

    test('uploadAvatar returns path on success', () async {
      final repo = ProProfileRepository(
        service: _FakeProProfileService(uploadedPath: 'uid/avatar.jpg'),
      );

      final path = await repo.uploadAvatar(file: File('fake.jpg'));
      expect(path, 'uid/avatar.jpg');
    });

    test('uploadAvatar wraps AuthException in ProProfileFailure', () async {
      final repo = ProProfileRepository(
        service: _FakeProProfileService(
          throwOn: const AuthException('Not authenticated'),
        ),
      );

      await expectLater(
        () => repo.uploadAvatar(file: File('fake.jpg')),
        throwsA(isA<ProProfileFailure>()),
      );
    });

    test('getSignedAvatarUrl returns null when service returns null', () async {
      final repo = ProProfileRepository(
        service: _FakeProProfileService(),
      );

      expect(await repo.getSignedAvatarUrl('uid/avatar.jpg'), isNull);
    });
  });
}

class _CapturingService extends ProProfileService {
  _CapturingService({required this.onUpdate});

  final Future<void> Function({
    required String bio,
    required int? serviceRadiusKm,
    String? fullName,
    String? nif,
    List<String>? credentialUrls,
  }) onUpdate;

  @override
  Future<ProProfileModel?> fetchCurrent() async => null;

  @override
  Future<void> updateProfile({
    required String bio,
    required int? serviceRadiusKm,
    String? fullName,
    String? nif,
    List<String>? credentialUrls,
  }) =>
      onUpdate(
        bio: bio,
        serviceRadiusKm: serviceRadiusKm,
        fullName: fullName,
        nif: nif,
        credentialUrls: credentialUrls,
      );

  @override
  Future<String> uploadAvatar({required File file}) async =>
      'uid/avatar.jpg';

  @override
  Future<String?> getSignedAvatarUrl(String path) async => null;
}
