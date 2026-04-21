import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/client/job_history/data/models/job_history_model.dart';

void main() {
  group('ClientJob', () {
    test('fromJson parses fields and leaves tradeName null', () {
      final job = ClientJob.fromJson({
        'id': 'job-1',
        'title': 'Fix sink',
        'description': 'Leak',
        'address_text': 'Rua X, 12',
        'status': 'pending',
        'created_at': '2026-04-10T09:00:00Z',
        'accepted_at': null,
        'pro_id': null,
        'trade_id': 7,
      });

      expect(job.id, 'job-1');
      expect(job.title, 'Fix sink');
      expect(job.tradeId, 7);
      expect(job.tradeName, isNull);
      expect(job.createdAt, isNotNull);
      expect(job.acceptedAt, isNull);
    });

    test('isPast reflects completed or cancelled statuses', () {
      ClientJob make(String status) => ClientJob.fromJson({
        'id': 'j',
        'title': '',
        'description': '',
        'status': status,
      });

      expect(make('pending').isPast, isFalse);
      expect(make('accepted').isPast, isFalse);
      expect(make('completed').isPast, isTrue);
      expect(make('cancelled').isPast, isTrue);
    });

    test('copyWith updates tradeName without touching other fields', () {
      final job = ClientJob.fromJson({
        'id': 'j1',
        'title': 't',
        'description': 'd',
        'status': 'pending',
        'trade_id': 3,
      });

      final updated = job.copyWith(tradeName: 'Plumbing');

      expect(updated.tradeName, 'Plumbing');
      expect(updated.id, job.id);
      expect(updated.tradeId, job.tradeId);
    });
  });
}
