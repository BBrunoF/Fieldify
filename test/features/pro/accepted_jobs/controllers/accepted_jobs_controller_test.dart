import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/accepted_jobs/controllers/accepted_jobs_controller.dart';
import 'package:project/features/pro/accepted_jobs/data/models/accepted_job.dart';
import 'package:project/features/pro/accepted_jobs/data/repositories/accepted_jobs_repository.dart';

class _FakeAcceptedJobsRepository extends AcceptedJobsRepository {
  _FakeAcceptedJobsRepository({this.onFetch});

  final Future<List<AcceptedJob>> Function()? onFetch;

  @override
  Future<List<AcceptedJob>> fetchAcceptedJobs() async {
    return await onFetch?.call() ?? const [];
  }
}

const _job = AcceptedJob(
  id: 'job-1',
  title: 'Pipe leak',
  description: 'Water under the sink',
  addressText: 'Rua das Flores 20',
  status: 'accepted',
  createdAt: null,
  acceptedAt: null,
  clientId: 'client-1',
);

void main() {
  group('AcceptedJobsController', () {
    test('loads accepted jobs', () async {
      final controller = AcceptedJobsController(
        repository: _FakeAcceptedJobsRepository(
          onFetch: () async => const [_job],
        ),
      );

      await controller.loadJobs();

      expect(controller.jobs, hasLength(1));
      expect(controller.isLoading, isFalse);
      expect(controller.error, isNull);
    });

    test('stores errors and clears stale jobs when loading fails', () async {
      final controller = AcceptedJobsController(
        repository: _FakeAcceptedJobsRepository(
          onFetch: () async {
            throw const AcceptedJobsFailure('Could not load accepted jobs');
          },
        ),
      );

      await controller.loadJobs();

      expect(controller.jobs, isEmpty);
      expect(controller.error, 'Could not load accepted jobs');
    });
  });
}
