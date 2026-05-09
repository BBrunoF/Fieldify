import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/jobs/controllers/pro_jobs_controller.dart';
import 'package:project/features/pro/jobs/data/models/pro_job.dart';
import 'package:project/features/pro/jobs/data/repositories/pro_jobs_repository.dart';

class _FakeProJobsRepository extends ProJobsRepository {
  _FakeProJobsRepository({this.onFetch, this.onAccept, this.onReject});

  final Future<List<ProJob>> Function({required bool includeRejected})? onFetch;
  final Future<void> Function(String requestId)? onAccept;
  final Future<void> Function(String requestId)? onReject;

  @override
  Future<List<ProJob>> fetchIncomingJobs({
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

const _job = ProJob(
  id: 'job-1',
  title: 'Pipe leak',
  description: 'Water under the sink',
  addressText: 'Rua das Flores 20',
  status: 'pending',
  createdAt: null,
  acceptedAt: null,
  clientId: 'client-1',
);

void main() {
  group('ProJobsController (incoming)', () {
    test('loads jobs and forwards the rejected filter state', () async {
      final requestedFlags = <bool>[];
      final controller = ProJobsController(
        repository: _FakeProJobsRepository(
          onFetch: ({required includeRejected}) async {
            requestedFlags.add(includeRejected);
            return const [_job];
          },
        ),
      );

      await controller.loadIncomingJobs();
      await controller.setShowRejected(true);

      expect(requestedFlags, [false, true]);
      expect(controller.incomingJobs, hasLength(1));
      expect(controller.showRejected, isTrue);
    });

    test('removes a job from memory after accepting it', () async {
      final controller = ProJobsController(
        repository: _FakeProJobsRepository(
          onFetch: ({required includeRejected}) async => const [_job],
          onAccept: (requestId) async {
            expect(requestId, 'job-1');
          },
        ),
      );

      await controller.loadIncomingJobs();
      await controller.acceptJob('job-1');

      expect(controller.incomingJobs, isEmpty);
      expect(controller.error, isNull);
    });

    test('stores errors when rejecting a job fails', () async {
      final controller = ProJobsController(
        repository: _FakeProJobsRepository(
          onFetch: ({required includeRejected}) async => const [_job],
          onReject: (requestId) async {
            throw const ProJobsFailure('Could not reject job');
          },
        ),
      );

      await controller.loadIncomingJobs();
      await controller.rejectJob('job-1');

      expect(controller.incomingJobs, hasLength(1));
      expect(controller.error, 'Could not reject job');
    });
  });
}
