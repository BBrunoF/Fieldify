import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/jobs/data/models/pro_job.dart';
import 'package:project/features/pro/jobs/data/repositories/pro_jobs_repository.dart';
import 'package:project/features/pro/jobs/data/services/pro_jobs_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeProJobsService extends ProJobsService {
  _FakeProJobsService({this.onFetch, this.onReturn});

  final Future<List<ProJob>> Function()? onFetch;
  final Future<void> Function(String requestId)? onReturn;

  @override
  Future<List<ProJob>> fetchAcceptedJobs() async {
    return await onFetch?.call() ?? const [];
  }

  @override
  Future<void> returnJobToPending(String requestId) async {
    await onReturn?.call(requestId);
  }
}

const _job = ProJob(
  id: 'job-1',
  title: 'Pipe leak',
  description: 'Water under the sink',
  addressText: null,
  status: 'in_progress',
  createdAt: null,
  acceptedAt: null,
  clientId: 'client-1',
);

void main() {
  group('ProJobsRepository (accepted)', () {
    test('returns accepted jobs from the service', () async {
      final repository = ProJobsRepository(
        service: _FakeProJobsService(onFetch: () async => const [_job]),
      );

      final result = await repository.fetchAcceptedJobs();

      expect(result, const [_job]);
    });

    test('maps Postgrest errors into ProJobsFailure', () async {
      final repository = ProJobsRepository(
        service: _FakeProJobsService(
          onFetch: () async {
            throw const PostgrestException(message: 'RLS blocked');
          },
        ),
      );

      expect(
        repository.fetchAcceptedJobs,
        throwsA(
          isA<ProJobsFailure>().having(
            (failure) => failure.message,
            'message',
            'RLS blocked',
          ),
        ),
      );
    });

    test('maps release failures into ProJobsFailure', () async {
      final repository = ProJobsRepository(
        service: _FakeProJobsService(
          onReturn: (_) async {
            throw const ProJobReleaseException();
          },
        ),
      );

      expect(
        () => repository.returnJobToPending('job-1'),
        throwsA(
          isA<ProJobsFailure>().having(
            (failure) => failure.message,
            'message',
            'Could not return this job to incoming requests.',
          ),
        ),
      );
    });
  });
}
