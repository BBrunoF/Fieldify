import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/accepted_jobs/data/models/accepted_job.dart';
import 'package:project/features/pro/accepted_jobs/data/repositories/accepted_jobs_repository.dart';
import 'package:project/features/pro/accepted_jobs/data/services/accepted_jobs_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAcceptedJobsService extends AcceptedJobsService {
  _FakeAcceptedJobsService({this.onFetch, this.onReturn});

  final Future<List<AcceptedJob>> Function()? onFetch;
  final Future<void> Function(String requestId)? onReturn;

  @override
  Future<List<AcceptedJob>> fetchAcceptedJobs() async {
    return await onFetch?.call() ?? const [];
  }

  @override
  Future<void> returnJobToPending(String requestId) async {
    await onReturn?.call(requestId);
  }
}

void main() {
  group('AcceptedJobsRepository', () {
    test('returns accepted jobs from the service', () async {
      const job = AcceptedJob(
        id: 'job-1',
        title: 'Pipe leak',
        description: 'Water under the sink',
        addressText: null,
        status: 'in_progress',
        createdAt: null,
        acceptedAt: null,
        clientId: 'client-1',
      );
      final repository = AcceptedJobsRepository(
        service: _FakeAcceptedJobsService(onFetch: () async => const [job]),
      );

      final result = await repository.fetchAcceptedJobs();

      expect(result, const [job]);
    });

    test('maps Postgrest errors into AcceptedJobsFailure', () async {
      final repository = AcceptedJobsRepository(
        service: _FakeAcceptedJobsService(
          onFetch: () async {
            throw const PostgrestException(message: 'RLS blocked');
          },
        ),
      );

      expect(
        repository.fetchAcceptedJobs,
        throwsA(
          isA<AcceptedJobsFailure>().having(
            (failure) => failure.message,
            'message',
            'RLS blocked',
          ),
        ),
      );
    });

    test('maps release failures into AcceptedJobsFailure', () async {
      final repository = AcceptedJobsRepository(
        service: _FakeAcceptedJobsService(
          onReturn: (_) async {
            throw const AcceptedJobReleaseException();
          },
        ),
      );

      expect(
        () => repository.returnJobToPending('job-1'),
        throwsA(
          isA<AcceptedJobsFailure>().having(
            (failure) => failure.message,
            'message',
            'Could not return this job to incoming requests.',
          ),
        ),
      );
    });
  });
}
