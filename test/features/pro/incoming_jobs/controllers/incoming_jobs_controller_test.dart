import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/incoming_jobs/controllers/incoming_jobs_controller.dart';
import 'package:project/features/pro/incoming_jobs/data/models/incoming_job.dart';
import 'package:project/features/pro/incoming_jobs/data/repositories/incoming_jobs_repository.dart';

class _FakeIncomingJobsRepository extends IncomingJobsRepository {
  _FakeIncomingJobsRepository({this.onFetch, this.onAccept, this.onReject});

  final Future<List<IncomingJob>> Function({required bool includeRejected})?
  onFetch;
  final Future<void> Function(String requestId)? onAccept;
  final Future<void> Function(String requestId)? onReject;

  @override
  Future<List<IncomingJob>> fetchIncomingJobs({
    bool includeRejected = false,
  }) async {
    return await onFetch?.call(includeRejected: includeRejected) ?? const [];
  }

  @override
  Future<void> acceptJob(String requestId) async {
    await onAccept?.call(requestId);
  }

  @override
  Future<void> rejectJob(String requestId) async {
    await onReject?.call(requestId);
  }
}

const _job = IncomingJob(
  id: 'job-1',
  title: 'Pipe leak',
  description: 'Water under the sink',
  addressText: 'Rua das Flores 20',
  status: 'pending',
  createdAt: null,
  clientId: 'client-1',
);

void main() {
  group('IncomingJobsController', () {
    test('loads jobs and forwards the rejected filter state', () async {
      final requestedFlags = <bool>[];
      final controller = IncomingJobsController(
        repository: _FakeIncomingJobsRepository(
          onFetch: ({required includeRejected}) async {
            requestedFlags.add(includeRejected);
            return const [_job];
          },
        ),
      );

      await controller.loadJobs();
      await controller.setShowRejected(true);

      expect(requestedFlags, [false, true]);
      expect(controller.jobs, hasLength(1));
      expect(controller.showRejected, isTrue);
    });

    test('removes a job from memory after accepting it', () async {
      final controller = IncomingJobsController(
        repository: _FakeIncomingJobsRepository(
          onFetch: ({required includeRejected}) async => const [_job],
          onAccept: (requestId) async {
            expect(requestId, 'job-1');
          },
        ),
      );

      await controller.loadJobs();
      await controller.acceptJob('job-1');

      expect(controller.jobs, isEmpty);
      expect(controller.error, isNull);
    });

    test('stores errors when rejecting a job fails', () async {
      final controller = IncomingJobsController(
        repository: _FakeIncomingJobsRepository(
          onFetch: ({required includeRejected}) async => const [_job],
          onReject: (requestId) async {
            throw const IncomingJobsFailure('Could not reject job');
          },
        ),
      );

      await controller.loadJobs();
      await controller.rejectJob('job-1');

      expect(controller.jobs, hasLength(1));
      expect(controller.error, 'Could not reject job');
    });
  });
}
