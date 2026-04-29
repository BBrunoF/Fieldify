import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/profile/controllers/pro_profile_controller.dart';
import 'package:project/features/pro/profile/data/models/pro_profile_model.dart';
import 'package:project/features/pro/profile/data/repositories/pro_profile_repository.dart';
import 'package:project/features/pro/profile/presentation/screens/pro_profile_screen.dart';

import '../../../../../test_helpers.dart';

class _FakeProProfileRepository extends ProProfileRepository {
  _FakeProProfileRepository({this.profile, this.onUpdate});

  ProProfileModel? profile;
  final Future<void> Function()? onUpdate;

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
    profile = profile?.copyWith(bio: bio, serviceRadiusKm: serviceRadiusKm);
  }

  @override
  Future<String> uploadAvatar({required File file}) async =>
      'uid/avatar.jpg';

  @override
  Future<String?> getSignedAvatarUrl(String path) async => null;
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

    testWidgets('shows radius field', (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _pending)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('proProfileRadiusField')), findsOneWidget);
    });

    testWidgets('radius field is pre-filled with current value', (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _pending)),
      );
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(
        find.byKey(const Key('proProfileRadiusField')),
      );
      expect(field.controller?.text, '20');
    });

    testWidgets('radius field is empty when serviceRadiusKm is null',
        (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _rejected)),
      );
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(
        find.byKey(const Key('proProfileRadiusField')),
      );
      expect(field.controller?.text, '');
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

    testWidgets('adding a credential marks form as dirty', (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _pending)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('proProfileAddCredentialField')),
        'https://example.com/new.pdf',
      );
      await tester.tap(find.byKey(const Key('proProfileAddCredentialButton')));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('proProfileSaveButton')),
      );
      expect(button.onPressed, isNotNull);
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

    testWidgets('save button is enabled after editing the radius', (tester) async {
      await pumpTestApp(
        tester,
        ProProfileScreen(controller: _controller(profile: _pending)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('proProfileRadiusField')),
        '50',
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
  });
}
