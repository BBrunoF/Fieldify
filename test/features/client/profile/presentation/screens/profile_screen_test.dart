import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/client/profile/controllers/profile_controller.dart';
import 'package:project/features/client/profile/data/models/profile_model.dart';
import 'package:project/features/client/profile/data/repositories/profile_repository.dart';
import 'package:project/features/client/profile/presentation/screens/profile_screen.dart';

import '../../../../../test_helpers.dart';

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository({this.profile, this.onUpdate});

  ProfileModel? profile;
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
    profile = ProfileModel(
      fullName: '${firstName.trim()} ${lastName.trim()}',
      phone: phone,
      email: profile?.email ?? '',
      addresses: addresses,
    );
  }
}

ProfileController _controller({
  ProfileModel? profile,
  Future<void> Function()? onUpdate,
}) {
  return ProfileController(
    repository: _FakeProfileRepository(
      profile: profile,
      onUpdate: onUpdate,
    ),
  );
}

const _profile = ProfileModel(
  fullName: 'Bruno Silva',
  phone: '912000000',
  email: 'bruno@example.com',
  addresses: [],
);

void main() {
  group('ProfileScreen', () {
    testWidgets('shows profile fields pre-filled with current profile data',
        (tester) async {
      await pumpTestApp(
        tester,
        ProfileScreen(controller: _controller(profile: _profile)),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('profileFirstNameField')),
            )
            .controller
            ?.text,
        'Bruno',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('profileLastNameField')),
            )
            .controller
            ?.text,
        'Silva',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('profilePhoneField')),
            )
            .controller
            ?.text,
        '912000000',
      );
    });

    testWidgets('save button is disabled when form has not been changed',
        (tester) async {
      await pumpTestApp(
        tester,
        ProfileScreen(controller: _controller(profile: _profile)),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('profileSaveButton')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('save button is enabled after editing a field', (tester) async {
      await pumpTestApp(
        tester,
        ProfileScreen(controller: _controller(profile: _profile)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('profileFirstNameField')), 'Ana');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('profileSaveButton')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows validation error when first name is too short',
        (tester) async {
      await pumpTestApp(
        tester,
        ProfileScreen(controller: _controller(profile: _profile)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('profileFirstNameField')), 'A');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('profileSaveButton')));
      await tester.tap(find.byKey(const Key('profileSaveButton')));
      await tester.pump();

      expect(find.text('First name is too short'), findsOneWidget);
    });

    testWidgets('shows validation error when phone is invalid', (tester) async {
      await pumpTestApp(
        tester,
        ProfileScreen(controller: _controller(profile: _profile)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('profilePhoneField')), '123');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('profileSaveButton')));
      await tester.tap(find.byKey(const Key('profileSaveButton')));
      await tester.pump();

      expect(find.text('Invalid phone number'), findsOneWidget);
    });

    testWidgets('shows "No saved addresses" when profile has no addresses',
        (tester) async {
      await pumpTestApp(
        tester,
        ProfileScreen(controller: _controller(profile: _profile)),
      );
      await tester.pumpAndSettle();

      expect(find.text('No saved addresses'), findsOneWidget);
    });

    testWidgets('shows address list when profile has addresses', (tester) async {
      const profileWithAddress = ProfileModel(
        fullName: 'Bruno Silva',
        phone: '912000000',
        email: 'bruno@example.com',
        addresses: ['Rua do Heroísmo 42, Porto'],
      );

      await pumpTestApp(
        tester,
        ProfileScreen(controller: _controller(profile: profileWithAddress)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rua do Heroísmo 42, Porto'), findsOneWidget);
    });

    testWidgets('shows "Profile updated" snackbar on successful save',
        (tester) async {
      await pumpTestApp(
        tester,
        ProfileScreen(
          controller: _controller(
            profile: _profile,
            onUpdate: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('profileFirstNameField')), 'Ana');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('profileSaveButton')));
      await tester.tap(find.byKey(const Key('profileSaveButton')));
      await tester.pumpAndSettle();

      expect(find.text('Profile updated'), findsOneWidget);
    });

    testWidgets('shows error snackbar when save fails', (tester) async {
      await pumpTestApp(
        tester,
        ProfileScreen(
          controller: _controller(
            profile: _profile,
            onUpdate: () async => throw Exception('Network error'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('profileFirstNameField')), 'Ana');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('profileSaveButton')));
      await tester.tap(find.byKey(const Key('profileSaveButton')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('save button is disabled again after successful save',
        (tester) async {
      await pumpTestApp(
        tester,
        ProfileScreen(
          controller: _controller(
            profile: _profile,
            onUpdate: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('profileFirstNameField')), 'Ana');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('profileSaveButton')));
      await tester.tap(find.byKey(const Key('profileSaveButton')));
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('profileSaveButton')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('shows My profile header title', (tester) async {
      await pumpTestApp(
        tester,
        ProfileScreen(controller: _controller(profile: _profile)),
      );
      await tester.pumpAndSettle();

      expect(find.text('My profile'), findsOneWidget);
    });
  });
}
