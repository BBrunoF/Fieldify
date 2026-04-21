import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/incoming_jobs/data/models/incoming_job.dart';

void main() {
  test('IncomingJob.fromJson maps data and rejected state', () {
    final job = IncomingJob.fromJson({
      'id': 'job-1',
      'title': 'Pipe repair',
      'description': 'Kitchen pipe is leaking',
      'address_text': 'Rua da Alegria 12',
      'status': 'pending',
      'created_at': '2026-04-20T08:30:00.000Z',
      'client_id': 'client-1',
    }, isRejected: true);

    expect(job.id, 'job-1');
    expect(job.title, 'Pipe repair');
    expect(job.description, 'Kitchen pipe is leaking');
    expect(job.addressText, 'Rua da Alegria 12');
    expect(job.status, 'pending');
    expect(job.createdAt, DateTime.parse('2026-04-20T08:30:00.000Z'));
    expect(job.clientId, 'client-1');
    expect(job.isRejected, isTrue);
  });
}
