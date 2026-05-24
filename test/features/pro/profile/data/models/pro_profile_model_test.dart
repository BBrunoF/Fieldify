import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/profile/data/models/pro_profile_model.dart';

const _pending = ProProfileModel(
  fullName: 'Bruno Silva',
  nif: '123456789',
  bio: 'Expert plumber with 10 years of experience.',
  verificationStatus: 'pending',
  avatarPath: null,
  tradeName: 'Plumbing',
  standardRate: 35,
  credentialUrls: ['https://example.com/cert1.pdf'],
  serviceRadiusKm: 20,
);

const _approved = ProProfileModel(
  fullName: 'Ana Costa',
  nif: '987654321',
  bio: '',
  verificationStatus: 'approved',
  avatarPath: 'uid/avatar.jpg',
  tradeName: 'Electrical',
  standardRate: 40,
  credentialUrls: [],
  serviceRadiusKm: null,
);

void main() {
  group('ProProfileModel', () {
    group('isApproved', () {
      test('returns true when verificationStatus is approved', () {
        expect(_approved.isApproved, isTrue);
      });

      test('returns false when verificationStatus is pending', () {
        expect(_pending.isApproved, isFalse);
      });

      test('returns false when verificationStatus is rejected', () {
        const rejected = ProProfileModel(
          fullName: 'X',
          nif: '111111111',
          bio: '',
          verificationStatus: 'rejected',
          avatarPath: null,
          tradeName: 'Other',
          standardRate: 30,
          credentialUrls: [],
        );
        expect(rejected.isApproved, isFalse);
      });
    });

    group('firstName / lastName', () {
      test('firstName returns the first word of fullName', () {
        expect(_pending.firstName, 'Bruno');
      });

      test('lastName returns everything after the first word', () {
        expect(_pending.lastName, 'Silva');
      });

      test('lastName returns multiple words when fullName has three parts', () {
        const model = ProProfileModel(
          fullName: 'Carlos Manuel Ramos',
          nif: '123456789',
          bio: '',
          verificationStatus: 'pending',
          avatarPath: null,
          tradeName: 'Plumbing',
          standardRate: 35,
          credentialUrls: [],
        );
        expect(model.lastName, 'Manuel Ramos');
      });

      test('firstName and lastName are empty when fullName is empty', () {
        const model = ProProfileModel(
          fullName: '',
          nif: '123456789',
          bio: '',
          verificationStatus: 'pending',
          avatarPath: null,
          tradeName: 'Plumbing',
          standardRate: 35,
          credentialUrls: [],
        );
        expect(model.firstName, '');
        expect(model.lastName, '');
      });
    });

    group('initials', () {
      test('returns two uppercase letters for a full name', () {
        expect(_pending.initials, 'BS');
      });

      test('returns one letter when there is no last name', () {
        const model = ProProfileModel(
          fullName: 'Bruno',
          nif: '123456789',
          bio: '',
          verificationStatus: 'pending',
          avatarPath: null,
          tradeName: 'Plumbing',
          standardRate: 35,
          credentialUrls: [],
        );
        expect(model.initials, 'B');
      });

      test('returns ? when fullName is empty', () {
        const model = ProProfileModel(
          fullName: '',
          nif: '123456789',
          bio: '',
          verificationStatus: 'pending',
          avatarPath: null,
          tradeName: 'Plumbing',
          standardRate: 35,
          credentialUrls: [],
        );
        expect(model.initials, '?');
      });
    });

    group('copyWith', () {
      test('updates only the specified fields', () {
        final updated = _pending.copyWith(bio: 'New bio');

        expect(updated.bio, 'New bio');
        expect(updated.fullName, _pending.fullName);
        expect(updated.nif, _pending.nif);
        expect(updated.verificationStatus, _pending.verificationStatus);
        expect(updated.tradeName, _pending.tradeName);
        expect(updated.standardRate, _pending.standardRate);
        expect(updated.credentialUrls, _pending.credentialUrls);
        expect(updated.serviceRadiusKm, _pending.serviceRadiusKm);
      });

      test('updates avatarPath', () {
        final updated = _pending.copyWith(avatarPath: 'uid/avatar.png');
        expect(updated.avatarPath, 'uid/avatar.png');
      });

      test('preserves original avatarPath when not specified', () {
        final updated = _approved.copyWith(bio: 'Updated bio');
        expect(updated.avatarPath, 'uid/avatar.jpg');
      });

      test('updates verificationStatus', () {
        final updated = _pending.copyWith(verificationStatus: 'approved');
        expect(updated.isApproved, isTrue);
      });

      test('updates credentialUrls', () {
        final updated = _pending.copyWith(
          credentialUrls: ['https://example.com/cert2.pdf'],
        );
        expect(updated.credentialUrls, ['https://example.com/cert2.pdf']);
      });

      test('updates serviceRadiusKm', () {
        final updated = _pending.copyWith(serviceRadiusKm: 50);
        expect(updated.serviceRadiusKm, 50);
      });

      test('preserves credentialUrls when not specified', () {
        final updated = _pending.copyWith(bio: 'Changed');
        expect(updated.credentialUrls, _pending.credentialUrls);
      });
    });

    group('credentialUrls', () {
      test('defaults to empty list when none provided', () {
        expect(_approved.credentialUrls, isEmpty);
      });

      test('holds multiple urls', () {
        expect(_pending.credentialUrls, hasLength(1));
        expect(_pending.credentialUrls.first, 'https://example.com/cert1.pdf');
      });
    });

    group('serviceRadiusKm', () {
      test('is null when not provided', () {
        expect(_approved.serviceRadiusKm, isNull);
      });

      test('holds value when set', () {
        expect(_pending.serviceRadiusKm, 20);
      });
    });
  });

  group('ProRatingSummary.fromReviews', () {
    ProReview r(int rating) => ProReview(
          id: 'x',
          rating: rating,
          comment: null,
          clientName: 'c',
          createdAt: DateTime(2026, 4, 1),
        );

    test('returns empty when no reviews', () {
      final s = ProRatingSummary.fromReviews(const []);
      expect(s.count, 0);
      expect(s.average, 0);
    });

    test('returns the rating itself when there is one review', () {
      final s = ProRatingSummary.fromReviews([r(4)]);
      expect(s.count, 1);
      expect(s.average, 4);
    });

    test('computes a non-integer average over multiple reviews', () {
      final s = ProRatingSummary.fromReviews([r(5), r(4)]);
      expect(s.count, 2);
      expect(s.average, 4.5);
    });
  });

  group('ProReview.fromJson', () {
    test('reads the client name from a joined profiles map', () {
      final r = ProReview.fromJson({
        'id': 'r1',
        'rating': 5,
        'comment': 'Great',
        'created_at': '2026-04-11T09:00:00Z',
        'profiles': {'full_name': 'João Silva'},
      });
      expect(r.clientName, 'João Silva');
      expect(r.rating, 5);
      expect(r.comment, 'Great');
    });

    test('reads the client name when profiles is returned as a list', () {
      final r = ProReview.fromJson({
        'id': 'r1',
        'rating': 4,
        'comment': null,
        'created_at': '2026-04-11T09:00:00Z',
        'profiles': [
          {'full_name': 'Maria Pinto'},
        ],
      });
      expect(r.clientName, 'Maria Pinto');
      expect(r.comment, isNull);
    });

    test('falls back to empty client name when profiles is missing', () {
      final r = ProReview.fromJson({
        'id': 'r1',
        'rating': 3,
        'comment': null,
        'created_at': '2026-04-11T09:00:00Z',
      });
      expect(r.clientName, '');
    });
  });
}
