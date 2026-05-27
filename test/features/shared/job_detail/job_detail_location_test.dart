import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/shared/job_detail/data/models/job_detail_model.dart';

void main() {
  test('JobDetail parses lat/lng from the job row', () {
    final job = JobDetail.fromJson(
      jobRow: {
        'id': 'job-1',
        'title': 'Leak',
        'description': 'desc',
        'address_text': 'Rua X',
        'status': 'pending',
        'client_id': 'c-1',
        'pro_id': null,
        'trade_id': 1,
        'lat': 41.1579,
        'lng': -8.6291,
      },
      counterpartyRow: null,
      viewerRole: ViewerRole.client,
      photoUrls: const [],
    );
    expect(job.lat, 41.1579);
    expect(job.lng, -8.6291);
  });

  test('JobDetail tolerates a missing location', () {
    final job = JobDetail.fromJson(
      jobRow: {
        'id': 'job-2',
        'title': 'Leak',
        'description': 'desc',
        'address_text': 'Rua X',
        'status': 'pending',
        'client_id': 'c-1',
        'pro_id': null,
        'trade_id': 1,
      },
      counterpartyRow: null,
      viewerRole: ViewerRole.client,
      photoUrls: const [],
    );
    expect(job.lat, isNull);
    expect(job.lng, isNull);
  });
}
