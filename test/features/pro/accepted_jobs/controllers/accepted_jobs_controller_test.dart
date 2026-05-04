import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/accepted_jobs/controllers/accepted_jobs_controller.dart';
import 'package:project/features/pro/accepted_jobs/data/models/accepted_job.dart';
import 'package:project/features/pro/accepted_jobs/data/repositories/accepted_jobs_repository.dart';

class _FakeAcceptedJobsRepository extends AcceptedJobsRepository {
  _FakeAcceptedJobsRepository({this.onFetch, this.onReturn});

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

    test('removes a job after returning it to incoming requests', () async {
      final controller = AcceptedJobsController(
        repository: _FakeAcceptedJobsRepository(
          onFetch: () async => const [_job],
          onReturn: (requestId) async {
            expect(requestId, 'job-1');
          },
        ),
      );

      await controller.loadJobs();
      final returned = await controller.returnJobToPending('job-1');

      expect(returned, isTrue);
      expect(controller.jobs, isEmpty);
      expect(controller.error, isNull);
    });

    test('stores errors when returning a job fails', () async {
      final controller = AcceptedJobsController(
        repository: _FakeAcceptedJobsRepository(
          onFetch: () async => const [_job],
          onReturn: (_) async {
            throw const AcceptedJobsFailure('Could not release job');
          },
        ),
      );

      await controller.loadJobs();
      final returned = await controller.returnJobToPending('job-1');

      expect(returned, isFalse);
      expect(controller.jobs, hasLength(1));
      expect(controller.error, 'Could not release job');
    });
  });
}
