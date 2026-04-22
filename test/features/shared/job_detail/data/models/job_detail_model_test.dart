import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/shared/job_detail/data/models/job_detail_model.dart';

void main() {
  group('JobStatus', () {
    test('fromDb maps every known value', () {
      expect(JobStatus.fromDb('pending'), JobStatus.pending);
      expect(JobStatus.fromDb('accepted'), JobStatus.accepted);
      expect(JobStatus.fromDb('on_the_way'), JobStatus.onTheWay);
      expect(JobStatus.fromDb('in_progress'), JobStatus.inProgress);
      expect(JobStatus.fromDb('completed'), JobStatus.completed);
      expect(JobStatus.fromDb('cancelled'), JobStatus.cancelled);
    });

    test('fromDb falls back to pending on unknown strings', () {
      expect(JobStatus.fromDb('gibberish'), JobStatus.pending);
    });

    test('dbValue round-trips with fromDb', () {
      for (final s in JobStatus.values) {
        expect(JobStatus.fromDb(s.dbValue), s);
      }
    });

    test('isTerminal only true for completed and cancelled', () {
      expect(JobStatus.completed.isTerminal, isTrue);
      expect(JobStatus.cancelled.isTerminal, isTrue);
      expect(JobStatus.pending.isTerminal, isFalse);
      expect(JobStatus.inProgress.isTerminal, isFalse);
    });
  });

  group('TradeInfo', () {
    test('parses integer and numeric fields', () {
      final t = TradeInfo.fromJson({
        'id': 3,
        'display_name': 'Plumbing',
        'standard_rate': 35,
      });
      expect(t.id, 3);
      expect(t.displayName, 'Plumbing');
      expect(t.standardRate, 35.0);
    });

    test('defaults when fields missing', () {
      final t = TradeInfo.fromJson({'id': 1});
      expect(t.displayName, '');
      expect(t.standardRate, 0.0);
    });
  });

  group('Timeline', () {
    test('parses all timestamp fields and leaves missing ones null', () {
      final t = Timeline.fromJson({
        'created_at': '2026-04-10T09:00:00Z',
        'accepted_at': '2026-04-10T09:05:00Z',
        'cancelled_at': null,
        'cancel_reason': null,
      });
      expect(t.createdAt.isUtc, isTrue);
      expect(t.acceptedAt, isNotNull);
      expect(t.cancelledAt, isNull);
      expect(t.cancelReason, isNull);
    });

    test('uses now() when created_at is missing', () {
      final t = Timeline.fromJson({});
      expect(t.createdAt, isNotNull);
    });
  });

  group('CounterpartyInfo', () {
    test('initials picks first and last words', () {
      final c = CounterpartyInfo.fromProfile(
        profile: const {'id': 'u1', 'full_name': 'Manuel Ferreira'},
        viewerRole: ViewerRole.client,
      );
      expect(c.initials, 'MF');
    });

    test('initials falls back for single-word names', () {
      final c = CounterpartyInfo.fromProfile(
        profile: const {'id': 'u1', 'full_name': 'Madonna'},
        viewerRole: ViewerRole.client,
      );
      expect(c.initials, 'M');
    });

    test('initials handles empty names', () {
      final c = CounterpartyInfo.fromProfile(
        profile: const {'id': 'u1', 'full_name': ''},
        viewerRole: ViewerRole.client,
      );
      expect(c.initials, '??');
    });

    test('exposes pro trade and verified flag when viewer is client', () {
      final c = CounterpartyInfo.fromProfile(
        profile: const {
          'id': 'u1',
          'full_name': 'Manuel Ferreira',
          'professional_profiles': {'verification_status': 'verified'},
        },
        viewerRole: ViewerRole.client,
        tradeName: 'Plumbing',
      );
      expect(c.tradeName, 'Plumbing');
      expect(c.isVerifiedPro, isTrue);
      expect(c.phone, isNull);
    });

    test('exposes phone when viewer is pro (client counterparty)', () {
      final c = CounterpartyInfo.fromProfile(
        profile: const {
          'id': 'u1',
          'full_name': 'João Silva',
          'phone': '+351 912 345 678',
        },
        viewerRole: ViewerRole.pro,
      );
      expect(c.phone, '+351 912 345 678');
      expect(c.tradeName, isNull);
      expect(c.isVerifiedPro, isFalse);
    });

    test('handles professional_profiles returned as a list (embed shape)', () {
      final c = CounterpartyInfo.fromProfile(
        profile: const {
          'id': 'u1',
          'full_name': 'Ana Costa',
          'professional_profiles': [
            {'verification_status': 'verified'},
          ],
        },
        viewerRole: ViewerRole.client,
        tradeName: 'Electrical',
      );
      expect(c.isVerifiedPro, isTrue);
    });
  });

  group('JobDetail.fromJson', () {
    test('assembles a client-viewer detail with photos and counterparty', () {
      final detail = JobDetail.fromJson(
        jobRow: const {
          'id': 'j1',
          'title': 'Leaky pipe',
          'description': 'Drip drip',
          'address_text': 'Rua X',
          'status': 'accepted',
          'client_id': 'c1',
          'pro_id': 'p1',
          'trade_id': 3,
          'created_at': '2026-04-10T09:00:00Z',
          'accepted_at': '2026-04-10T09:10:00Z',
          'trades': {
            'id': 3,
            'display_name': 'Plumbing',
            'standard_rate': 35,
          },
        },
        counterpartyRow: const {
          'id': 'p1',
          'full_name': 'Manuel Ferreira',
          'professional_profiles': {'verification_status': 'verified'},
        },
        viewerRole: ViewerRole.client,
        photoUrls: const ['https://signed/a.jpg', 'https://signed/b.jpg'],
      );

      expect(detail.id, 'j1');
      expect(detail.status, JobStatus.accepted);
      expect(detail.trade.displayName, 'Plumbing');
      expect(detail.counterparty?.fullName, 'Manuel Ferreira');
      expect(detail.counterparty?.isVerifiedPro, isTrue);
      expect(detail.counterparty?.tradeName, 'Plumbing');
      expect(detail.photoUrls, hasLength(2));
      expect(detail.viewerRole, ViewerRole.client);
    });

    test('leaves counterparty null when no counterparty row provided', () {
      final detail = JobDetail.fromJson(
        jobRow: const {
          'id': 'j1',
          'title': 'x',
          'description': '',
          'address_text': '',
          'status': 'pending',
          'client_id': 'c1',
          'pro_id': null,
          'trade_id': 1,
          'trades': {'id': 1, 'display_name': 'General', 'standard_rate': 0},
          'created_at': '2026-04-10T09:00:00Z',
        },
        counterpartyRow: null,
        viewerRole: ViewerRole.client,
        photoUrls: const [],
      );

      expect(detail.counterparty, isNull);
      expect(detail.proId, isNull);
    });
  });
}
