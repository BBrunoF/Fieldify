import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/profile/controllers/pro_profile_controller.dart';
import 'package:project/features/pro/profile/controllers/work_settings_controller.dart';
import 'package:project/features/pro/profile/data/models/availability_schedule_model.dart';
import 'package:project/features/pro/profile/data/models/pro_profile_model.dart';
import 'package:project/features/pro/profile/data/repositories/pro_profile_repository.dart';
import 'package:project/features/pro/profile/data/repositories/work_settings_repository.dart';
import 'package:project/features/pro/profile/presentation/screens/pro_profile_screen.dart';

import '../../../../../test_helpers.dart';

class _FakeProProfileRepository extends ProProfileRepository {
  _FakeProProfileRepository({this.profile, this.onUpdate});

  ProProfileModel? profile;
  final Future<void> Function()? onUpdate;
  final List<String> deletedCredentials = [];

  @override
  Future<ProProfileModel?> fetchCurrent() async => profile;

  @override
  Future<void> deleteCredential(String path) async =>
      deletedCredentials.add(path);

  @override
  Future<void> updateProfile({
    required String bio,
    required int? serviceRadiusKm,
    String? fullName,
    String? nif,
    List<String>? credentialUrls,
  }) async {
    await onUpdate?.call();
    profile = profile?.copyWith(bio: bio, serviceRadiusKm: serviceRadiusKm);
  }

  @override
  Future<String> uploadAvatar({required File file}) async =>
      'uid/avatar.jpg';

  @override
  Future<String?> getSignedAvatarUrl(String path) async => null;

  @override
  Future<List<ProReview>> fetchCurrentReviews() async => const [];
}

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

/// No-op work-settings repository so widget tests don't touch Supabase and the
/// work-hours save never errors (which would otherwise mask profile snackbars).
class _FakeWorkSettingsRepository extends WorkSettingsRepository {
  @override
  Future<List<AvailabilityScheduleModel>> fetchSchedules() async => const [];

  @override
  Future<int?> fetchServiceRadius() async => null;

  @override
  Future<void> saveSchedules(List<AvailabilityScheduleModel> schedules) async {}

  @override
  Future<void> saveServiceRadius(int radiusKm) async {}

  @override
  Future<void> saveLocation({
    required double latitude,
    required double longitude,
  }) async {}
}

WorkSettingsController _workController() =>
    WorkSettingsController(repository: _FakeWorkSettingsRepository());

/// Work-settings repository whose load never completes, so the controller
/// stays in the loading state and the screen never marks work settings as
/// initialized. Records whether a save was (incorrectly) attempted.
class _BlockingWorkSettingsRepository extends WorkSettingsRepository {
  bool saveSchedulesCalled = false;
  final Completer<List<AvailabilityScheduleModel>> _never = Completer();

  @override
  Future<List<AvailabilityScheduleModel>> fetchSchedules() => _never.future;

  @override
  Future<int?> fetchServiceRadius() async => null;

  @override
  Future<void> saveSchedules(List<AvailabilityScheduleModel> schedules) async {
    saveSchedulesCalled = true;
  }

  @override
  Future<void> saveServiceRadius(int radiusKm) async {}

  @override
  Future<void> saveLocation({
    required double latitude,
    required double longitude,
  }) async {}
}

const _pending = ProProfileModel(
  fullName: 'Bruno Silva',
  nif: '123456789',
  bio: 'Expert plumber',
  verificationStatus: 'pending',
  avatarPath: null,
  tradeName: 'Plumbing',
  standardRate: 35,
  credentialUrls: ['https://example.com/cert.pdf'],
  serviceRadiusKm: 20,
);

const _approved = ProProfileModel(
  fullName: 'Ana Costa',
  nif: '987654321',
  bio: 'Experienced electrician',
  verificationStatus: 'approved',
  avatarPath: null,
  tradeName: 'Electrical',
  standardRate: 40,
  credentialUrls: ['https://example.com/license.pdf'],
  serviceRadiusKm: 15,
);

const _rejected = ProProfileModel(
  fullName: 'Carlos Ramos',
  nif: '111222333',
  bio: '',
  verificationStatus: 'rejected',
  avatarPath: null,
  tradeName: 'Carpentry',
  standardRate: 32,
  credentialUrls: [],
  serviceRadiusKm: null,
);

void main() {
  group('ProProfileScreen', () {
    testWidgets('shows My profile header title', (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _pending)),
      );
      await tester.pumpAndSettle();

      expect(find.text('My profile'), findsOneWidget);
    });

    testWidgets('shows bio field', (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _pending)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('proProfileBioField')), findsOneWidget);
    });

    testWidgets('bio field is pre-filled with current bio', (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _pending)),
      );
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(
        find.byKey(const Key('proProfileBioField')),
      );
      expect(field.controller?.text, 'Expert plumber');
    });

    testWidgets('shows radius slider', (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _pending)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('proProfileRadiusSlider')), findsOneWidget);
    });

    testWidgets('radius slider is pre-set with current value', (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _pending)),
      );
      await tester.pumpAndSettle();

      final slider = tester.widget<Slider>(
        find.byKey(const Key('proProfileRadiusSlider')),
      );
      expect(slider.value, 20.0);
    });

    testWidgets('radius slider defaults to 25 when serviceRadiusKm is null',
        (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _rejected)),
      );
      await tester.pumpAndSettle();

      final slider = tester.widget<Slider>(
        find.byKey(const Key('proProfileRadiusSlider')),
      );
      expect(slider.value, 25.0);
    });

    testWidgets(
        'shows editable name and NIF fields when profile is not approved',
        (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _pending)),
      );
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('proProfileFirstNameField')), findsOneWidget);
      expect(find.byKey(const Key('proProfileLastNameField')), findsOneWidget);
      expect(find.byKey(const Key('proProfileNifField')), findsOneWidget);
    });

    testWidgets(
        'shows locked name and NIF when profile is approved',
        (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _approved)),
      );
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('proProfileFirstNameField')), findsNothing);
      expect(find.byKey(const Key('proProfileNifField')), findsNothing);
      expect(find.text('Cannot change'), findsWidgets);
    });

    testWidgets('shows add credential button when not approved', (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _pending)),
      );
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('proProfileAddCredentialButton')), findsOneWidget);
    });

    testWidgets('does not show add credential button when approved',
        (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _approved)),
      );
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('proProfileAddCredentialButton')), findsNothing);
    });

    testWidgets('shows credential filename, stripping the uuid path prefix',
        (tester) async {
      const profile = ProProfileModel(
        fullName: 'Bruno Silva',
        nif: '123456789',
        bio: 'Expert plumber',
        verificationStatus: 'pending',
        avatarPath: null,
        tradeName: 'Plumbing',
        standardRate: 35,
        credentialUrls: [
          'abc12345-1111-2222-3333-444455556666/'
              '0a1b2c3d-4e5f-6789-abcd-ef0123456789_license.pdf',
        ],
        serviceRadiusKm: 20,
      );
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: profile)),
      );
      await tester.pumpAndSettle();

      expect(find.text('license.pdf'), findsOneWidget);
    });

    testWidgets('does not save work hours before the schedule has loaded',
        (tester) async {
      // Regression: tapping Save before the work schedule loads must NOT push
      // an empty schedule (which would wipe the pro's saved availability).
      final workRepo = _BlockingWorkSettingsRepository();
      await pumpTestApp(
        tester,
        ProProfileScreen(
          controller: _controller(profile: _pending, onUpdate: () async {}),
          workController: WorkSettingsController(repository: workRepo),
        ),
      );
      await tester.pump(); // not pumpAndSettle — work load never completes

      await tester.enterText(
        find.byKey(const Key('proProfileBioField')),
        'Updated bio text',
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('proProfileSaveButton')));
      await tester.tap(find.byKey(const Key('proProfileSaveButton')));
      await tester.pump();

      expect(workRepo.saveSchedulesCalled, isFalse);
    });

    testWidgets(
        'removing a credential deletes its file only after a successful save',
        (tester) async {
      final repo = _FakeProProfileRepository(
        profile: _pending, // has one credential
        onUpdate: () async {},
      );
      final controller = ProProfileController(repository: repo);
      await pumpTestApp(
        tester,
        ProProfileScreen(
          controller: controller,
          workController: _workController(),
        ),
      );
      await tester.pumpAndSettle();

      // Remove the credential — must NOT delete from storage yet.
      await tester.ensureVisible(
          find.byKey(const Key('proProfileRemoveCredential_0')));
      await tester.tap(find.byKey(const Key('proProfileRemoveCredential_0')));
      await tester.pump();
      expect(repo.deletedCredentials, isEmpty);

      // Saving persists the new list, then purges the removed file.
      await tester.ensureVisible(find.byKey(const Key('proProfileSaveButton')));
      await tester.tap(find.byKey(const Key('proProfileSaveButton')));
      await tester.pumpAndSettle();
      expect(repo.deletedCredentials, ['https://example.com/cert.pdf']);
    });

    testWidgets('shows "Under review" badge for pending profile',
        (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _pending)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Under review'), findsOneWidget);
    });

    testWidgets('shows "Verified" badge for approved profile', (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _approved)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verified'), findsOneWidget);
    });

    testWidgets('shows "Not approved" badge for rejected profile',
        (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _rejected)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Not approved'), findsOneWidget);
    });

    testWidgets('shows trade name and standard rate', (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _pending)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Plumbing'), findsOneWidget);
      expect(find.text('€35/h'), findsOneWidget);
    });

    testWidgets('save button is disabled when form has not been changed',
        (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _pending)),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('proProfileSaveButton')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('save button is enabled after editing the bio', (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _pending)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('proProfileBioField')),
        'Updated bio text',
      );
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('proProfileSaveButton')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('save button is enabled after dragging the radius slider',
        (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _pending)),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
          find.byKey(const Key('proProfileRadiusSlider')));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const Key('proProfileRadiusSlider')),
        const Offset(100, 0),
      );
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('proProfileSaveButton')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets(
        'save button is enabled after editing NIF when not approved',
        (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _pending)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('proProfileNifField')),
        '999888777',
      );
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('proProfileSaveButton')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows validation error when NIF is not 9 digits',
        (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _pending)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('proProfileNifField')),
        '123',
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('proProfileSaveButton')));
      await tester.tap(find.byKey(const Key('proProfileSaveButton')));
      await tester.pump();

      expect(find.text('NIF must be 9 digits'), findsOneWidget);
    });

    testWidgets('shows validation error when first name is too short',
        (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _pending)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('proProfileFirstNameField')),
        'A',
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('proProfileSaveButton')));
      await tester.tap(find.byKey(const Key('proProfileSaveButton')));
      await tester.pump();

      expect(find.text('First name is too short'), findsOneWidget);
    });

    testWidgets('shows "Profile updated" snackbar on successful save',
        (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(
          controller: _controller(
            profile: _pending,
            onUpdate: () async {},
          ),
          workController: _workController(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('proProfileBioField')),
        'Updated bio text',
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('proProfileSaveButton')));
      await tester.tap(find.byKey(const Key('proProfileSaveButton')));
      await tester.pumpAndSettle();

      expect(find.text('Profile updated'), findsOneWidget);
    });

    testWidgets('shows error snackbar when save fails', (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(
          controller: _controller(
            profile: _pending,
            onUpdate: () async => throw Exception('Network error'),
          ),
          workController: _workController(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('proProfileBioField')),
        'Updated bio text',
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('proProfileSaveButton')));
      await tester.tap(find.byKey(const Key('proProfileSaveButton')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('save button is disabled again after successful save',
        (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(
          controller: _controller(
            profile: _pending,
            onUpdate: () async {},
          ),
          workController: _workController(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('proProfileBioField')),
        'Updated bio text',
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('proProfileSaveButton')));
      await tester.tap(find.byKey(const Key('proProfileSaveButton')));
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('proProfileSaveButton')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('shows avatar edit button', (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _pending)),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('proProfileAvatarEditButton')),
        findsOneWidget,
      );
    });

    testWidgets('shows initials in avatar when no photo', (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _pending)),
      );
      await tester.pumpAndSettle();

      expect(find.text('BS'), findsOneWidget);
    });

    testWidgets('shows the client reviews section with no-reviews state',
        (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _pending)),
      );
      await tester.pumpAndSettle();

      expect(find.text('CLIENT REVIEWS'), findsOneWidget);
      expect(
        find.text('No reviews yet', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('shows average rating and review tiles when reviews exist',
        (tester) async {
      final controller = ProProfileController(
        repository: _ReviewingRepository(
          profile: _pending,
          reviews: [
            ProReview(
              id: 'r1',
              rating: 5,
              comment: 'Excellent work',
              clientName: 'João Silva',
              createdAt: DateTime(2026, 4, 11),
            ),
            ProReview(
              id: 'r2',
              rating: 3,
              comment: null,
              clientName: 'Maria Pinto',
              createdAt: DateTime(2026, 4, 12),
            ),
          ],
        ),
      );

      await pumpTestApp(
        tester,
        ProProfileScreen(controller: controller),
      );
      await tester.pumpAndSettle();

      expect(find.text('4.0'), findsOneWidget);
      expect(find.text('2 reviews'), findsOneWidget);
      expect(
        find.text('Excellent work', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('João Silva', skipOffstage: false),
        findsOneWidget,
      );
    });
  });
}

class _ReviewingRepository extends ProProfileRepository {
  _ReviewingRepository({required this.profile, this.reviews = const []});

  final ProProfileModel profile;
  final List<ProReview> reviews;

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
      'uid/avatar.jpg';

  @override
  Future<String?> getSignedAvatarUrl(String path) async => null;

  @override
  Future<List<ProReview>> fetchCurrentReviews() async => reviews;
}
