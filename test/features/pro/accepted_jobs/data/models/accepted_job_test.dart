import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/jobs/data/models/pro_job.dart';

void main() {
  test('ProJob.fromJson maps accepted job data', () {
    final job = ProJob.fromJson({
      'id': 'job-1',
      'title': 'Install sink',
      'description': 'Fit the new bathroom sink',
      'address_text': 'Rua da Alegria 12',
      'status': 'on_my_way',
      'created_at': '2026-04-20T08:30:00.000Z',
      'accepted_at': '2026-04-21T09:45:00.000Z',
      'client_id': 'client-1',
    });

    expect(job.id, 'job-1');
    expect(job.title, 'Install sink');
    expect(job.description, 'Fit the new bathroom sink');
    expect(job.addressText, 'Rua da Alegria 12');
    expect(job.status, 'on_my_way');
    expect(job.createdAt, DateTime.parse('2026-04-20T08:30:00.000Z'));
    expect(job.acceptedAt, DateTime.parse('2026-04-21T09:45:00.000Z'));
    expect(job.clientId, 'client-1');
  });
}
