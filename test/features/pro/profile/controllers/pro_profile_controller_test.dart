import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/profile/controllers/pro_profile_controller.dart';
import 'package:project/features/pro/profile/data/models/pro_profile_model.dart';
import 'package:project/features/pro/profile/data/repositories/pro_profile_repository.dart';

class _FakeProProfileRepository extends ProProfileRepository {
  _FakeProProfileRepository({
    this.profile,
    this.onUpdate,
    this.uploadedPath = 'uid/avatar.jpg',
  });

  ProProfileModel? profile;
  final Future<void> Function()? onUpdate;
  final String uploadedPath;

  @override
  Future<ProProfileModel?> fetchCurrent() async => profile;

  @override
  Future<void> updateProfile({
    required String bio,
    required int? serviceRadiusKm,
    String? fullName,
    String? nif,
    List<String>? credentialUrls,
  }) async {
    await onUpdate?.call();
    profile = profile?.copyWith(
      bio: bio,
      serviceRadiusKm: serviceRadiusKm,
      credentialUrls: credentialUrls,
    );
  }

  @override
  Future<String> uploadAvatar({required File file}) async => uploadedPath;

  @override
  Future<String?> getSignedAvatarUrl(String path) async => null;
}

const _pendingProfile = ProProfileModel(
  fullName: 'Bruno Silva',
  nif: '123456789',
  bio: 'Experienced plumber',
  verificationStatus: 'pending',
  avatarPath: null,
  tradeName: 'Plumbing',
  standardRate: 35,
  credentialUrls: ['https://example.com/cert.pdf'],
  serviceRadiusKm: 20,
);

const _approvedProfile = ProProfileModel(
  fullName: 'Ana Costa',
  nif: '987654321',
  bio: '',
  verificationStatus: 'approved',
  avatarPath: null,
  tradeName: 'Electrical',
  standardRate: 40,
  credentialUrls: ['https://example.com/license.pdf'],
  serviceRadiusKm: 15,
);

ProProfileController _controller({
  ProProfileModel? profile,
  Future<void> Function()? onUpdate,
}) {
  return ProProfileController(
    repository: _FakeProProfileRepository(
      profile: profile,
      onUpdate: onUpdate,
    ),
  );
}

void main() {
  group('ProProfileController', () {
    test('profile is loaded from repository on construction', () async {
      final controller = _controller(profile: _pendingProfile);

      await Future<void>.delayed(Duration.zero);
      expect(controller.profile?.fullName, 'Bruno Silva');
      expect(controller.isLoading, isFalse);
      expect(controller.isSaving, isFalse);
      expect(controller.error, isNull);
      expect(controller.saved, isFalse);
    });

    test('profile is null when repository returns null', () async {
      final controller = _controller(profile: null);

      await Future<void>.delayed(Duration.zero);
      expect(controller.profile, isNull);
    });

    test('saveProfile sets isSaving to true then false', () async {
      final savingStates = <bool>[];

      final controller = _controller(
        profile: _pendingProfile,
        onUpdate: () async {},
      );

      controller.addListener(() => savingStates.add(controller.isSaving));

      await controller.saveProfile(
        bio: 'New bio',
        firstName: 'Bruno',
        lastName: 'Silva',
        nif: '123456789',
        serviceRadiusKm: 30,
        credentialUrls: ['https://example.com/cert.pdf'],
      );

      expect(savingStates.first, isTrue);
      expect(savingStates.last, isFalse);
    });

    test('saveProfile on success sets saved=true and clears error', () async {
      final controller = _controller(
        profile: _pendingProfile,
        onUpdate: () async {},
      );

      await controller.saveProfile(
        bio: 'New bio',
        firstName: 'Bruno',
        lastName: 'Silva',
        nif: '123456789',
        serviceRadiusKm: 30,
      );

      expect(controller.saved, isTrue);
      expect(controller.error, isNull);
      expect(controller.isSaving, isFalse);
    });

    test('saveProfile on failure stores error and clears saved', () async {
      final controller = ProProfileController(
        repository: _FakeProProfileRepository(
          profile: _pendingProfile,
          onUpdate: () async => throw Exception('Network error'),
        ),
      );

      await controller.saveProfile(
        bio: 'New bio',
        firstName: 'Bruno',
        lastName: 'Silva',
        nif: '123456789',
        serviceRadiusKm: null,
      );

      expect(controller.error, isNotNull);
      expect(controller.saved, isFalse);
      expect(controller.isSaving, isFalse);
    });

    test(
        'saveProfile completes when profile is approved — credentials and name not passed',
        () async {
      final controller = ProProfileController(
        repository: _FakeProProfileRepository(
          profile: _approvedProfile,
          onUpdate: () async {},
        ),
      );
      await Future<void>.delayed(Duration.zero);

      await controller.saveProfile(
        bio: 'Updated bio',
        firstName: 'Ana',
        lastName: 'Costa',
        nif: '987654321',
        serviceRadiusKm: 25,
        credentialUrls: ['https://new.com/cert.pdf'],
      );

      expect(controller.saved, isTrue);
      expect(controller.error, isNull);
    });

    test('saveProfile passes serviceRadiusKm when provided', () async {
      int? capturedRadius;

      final repo = _CapturingRepository(
        profile: _pendingProfile,
        onUpdate: ({
          required bio,
          required serviceRadiusKm,
          fullName,
          nif,
          credentialUrls,
        }) async {
          capturedRadius = serviceRadiusKm;
        },
      );

      final controller = ProProfileController(repository: repo);
      await Future<void>.delayed(Duration.zero);

      await controller.saveProfile(
        bio: 'Bio',
        firstName: 'Bruno',
        lastName: 'Silva',
        nif: '123456789',
        serviceRadiusKm: 50,
      );

      expect(capturedRadius, 50);
    });

    test('saveProfile does not pass credentialUrls when profile is approved',
        () async {
      List<String>? capturedUrls;
      bool updateCalled = false;

      final repo = _CapturingRepository(
        profile: _approvedProfile,
        onUpdate: ({
          required bio,
          required serviceRadiusKm,
          fullName,
          nif,
          credentialUrls,
        }) async {
          updateCalled = true;
          capturedUrls = credentialUrls;
        },
      );

      final controller = ProProfileController(repository: repo);
      await Future<void>.delayed(Duration.zero);

      await controller.saveProfile(
        bio: 'Bio',
        firstName: 'Ana',
        lastName: 'Costa',
        nif: '987654321',
        serviceRadiusKm: 15,
        credentialUrls: ['https://new.com/new.pdf'],
      );

      expect(updateCalled, isTrue);
      expect(capturedUrls, isNull);
    });

    test('uploadAvatar sets isUploadingAvatar to true then false', () async {
      final uploadingStates = <bool>[];

      final controller = _controller(profile: _pendingProfile);
      await Future<void>.delayed(Duration.zero);

      controller.addListener(
        () => uploadingStates.add(controller.isUploadingAvatar),
      );

      await controller.uploadAvatar(File('fake.jpg'));

      expect(uploadingStates.first, isTrue);
      expect(uploadingStates.last, isFalse);
    });

    test('uploadAvatar updates avatarPath on success', () async {
      final controller = ProProfileController(
        repository: _FakeProProfileRepository(
          profile: _pendingProfile,
          uploadedPath: 'uid/avatar.jpg',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      await controller.uploadAvatar(File('fake.jpg'));

      expect(controller.profile?.avatarPath, 'uid/avatar.jpg');
    });

    test('uploadAvatar stores error on failure', () async {
      final controller = ProProfileController(
        repository: _ThrowingUploadRepository(profile: _pendingProfile),
      );
      await Future<void>.delayed(Duration.zero);

      await controller.uploadAvatar(File('fake.jpg'));

      expect(controller.error, isNotNull);
      expect(controller.isUploadingAvatar, isFalse);
    });

    test('clearError resets the error state', () async {
      final controller = ProProfileController(
        repository: _FakeProProfileRepository(
          profile: _pendingProfile,
          onUpdate: () async => throw Exception('boom'),
        ),
      );

      await controller.saveProfile(
        bio: 'New bio',
        firstName: 'Bruno',
        lastName: 'Silva',
        nif: '123456789',
        serviceRadiusKm: null,
      );

      expect(controller.error, isNotNull);
      controller.clearError();
      expect(controller.error, isNull);
    });

    test('clearSaved resets the saved state', () async {
      final controller = _controller(
        profile: _pendingProfile,
        onUpdate: () async {},
      );

      await controller.saveProfile(
        bio: 'New bio',
        firstName: 'Bruno',
        lastName: 'Silva',
        nif: '123456789',
        serviceRadiusKm: null,
      );

      expect(controller.saved, isTrue);
      controller.clearSaved();
      expect(controller.saved, isFalse);
    });

    test('notifyListeners is called on saveProfile completion', () async {
      int notifyCount = 0;

      final controller = _controller(
        profile: _pendingProfile,
        onUpdate: () async {},
      );
      controller.addListener(() => notifyCount++);

      await controller.saveProfile(
        bio: 'New bio',
        firstName: 'Bruno',
        lastName: 'Silva',
        nif: '123456789',
        serviceRadiusKm: null,
      );

      expect(notifyCount, greaterThanOrEqualTo(2));
    });
  });
}

class _CapturingRepository extends ProProfileRepository {
  _CapturingRepository({required this.profile, required this.onUpdate});

  final ProProfileModel profile;
  final Future<void> Function({
    required String bio,
    required int? serviceRadiusKm,
    String? fullName,
    String? nif,
    List<String>? credentialUrls,
  }) onUpdate;

  @override
  Future<ProProfileModel?> fetchCurrent() async => profile;

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

class _ThrowingUploadRepository extends ProProfileRepository {
  _ThrowingUploadRepository({required this.profile});
  final ProProfileModel? profile;

  @override
  Future<ProProfileModel?> fetchCurrent() async => profile;

  @override
  Future<void> updateProfile({
    required String bio,
    required int? serviceRadiusKm,
    String? fullName,
    String? nif,
    List<String>? credentialUrls,
  }) async {}

  @override
  Future<String> uploadAvatar({required File file}) async =>
      throw Exception('Upload failed');

  @override
  Future<String?> getSignedAvatarUrl(String path) async => null;
}
