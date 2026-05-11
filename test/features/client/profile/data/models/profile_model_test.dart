import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/client/profile/data/models/profile_model.dart';

void main() {
  group('ProfileModel', () {
    test('fromMeta parses all fields correctly', () {
      final model = ProfileModel.fromMeta(
        {
          'full_name': 'Bruno Silva',
          'phone': '+351912345678',
          'addresses': ['Rua do Heroísmo 42, Porto'],
        },
        'bruno@example.com',
      );

      expect(model.fullName, 'Bruno Silva');
      expect(model.phone, '+351912345678');
      expect(model.email, 'bruno@example.com');
      expect(model.addresses, ['Rua do Heroísmo 42, Porto']);
    });

    test('firstName returns the first word of fullName', () {
      final model = ProfileModel.fromMeta(
        {'full_name': 'Bruno Silva'},
        '',
      );
      expect(model.firstName, 'Bruno');
    });

    test('lastName returns everything after the first word', () {
      final model = ProfileModel.fromMeta(
        {'full_name': 'Bruno Silva Costa'},
        '',
      );
      expect(model.lastName, 'Silva Costa');
    });

    test('firstName and lastName are empty when fullName is empty', () {
      final model = ProfileModel.fromMeta({'full_name': ''}, '');
      expect(model.firstName, '');
      expect(model.lastName, '');
    });

    test('addresses defaults to empty list when missing from meta', () {
      final model = ProfileModel.fromMeta({'full_name': 'Ana'}, '');
      expect(model.addresses, isEmpty);
    });

    test('addresses defaults to empty list when meta value is not a list', () {
      final model = ProfileModel.fromMeta(
        {'full_name': 'Ana', 'addresses': 'not-a-list'},
        '',
      );
      expect(model.addresses, isEmpty);
    });

    test('copyWith updates only the specified fields', () {
      const original = ProfileModel(
        fullName: 'Bruno Silva',
        phone: '912000000',
        email: 'bruno@example.com',
        addresses: [],
      );

      final updated = original.copyWith(fullName: 'Ana Costa');

      expect(updated.fullName, 'Ana Costa');
      expect(updated.phone, original.phone);
      expect(updated.email, original.email);
    });

    test('copyWith with addresses replaces the list', () {
      const original = ProfileModel(
        fullName: 'Bruno',
        phone: '',
        email: '',
        addresses: ['Old address 1'],
      );

      final updated = original.copyWith(
        addresses: ['New street 42, Porto', 'Second street 10, Lisboa'],
      );

      expect(updated.addresses, hasLength(2));
      expect(updated.addresses.first, 'New street 42, Porto');
    });

    test('copyWith updates avatarPath', () {
      const original = ProfileModel(
        fullName: 'Bruno Silva',
        phone: '912000000',
        email: 'bruno@example.com',
        addresses: [],
      );

      final updated = original.copyWith(avatarPath: 'uid/avatar.jpg');
      expect(updated.avatarPath, 'uid/avatar.jpg');
    });

    test('copyWith preserves avatarPath when not specified', () {
      const original = ProfileModel(
        fullName: 'Bruno Silva',
        phone: '912000000',
        email: 'bruno@example.com',
        addresses: [],
        avatarPath: 'uid/avatar.jpg',
      );

      final updated = original.copyWith(phone: '913000000');
      expect(updated.avatarPath, 'uid/avatar.jpg');
    });

    test('initials returns two uppercase letters for a full name', () {
      final model = ProfileModel.fromMeta({'full_name': 'Bruno Silva'}, '');
      expect(model.initials, 'BS');
    });

    test('initials returns one letter when there is no last name', () {
      final model = ProfileModel.fromMeta({'full_name': 'Bruno'}, '');
      expect(model.initials, 'B');
    });

    test('initials returns ? when fullName is empty', () {
      final model = ProfileModel.fromMeta({'full_name': ''}, '');
      expect(model.initials, '?');
    });
  });
}
