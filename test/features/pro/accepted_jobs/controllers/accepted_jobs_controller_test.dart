import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/jobs/controllers/pro_jobs_controller.dart';
import 'package:project/features/pro/jobs/data/models/pro_job.dart';
import 'package:project/features/pro/jobs/data/repositories/pro_jobs_repository.dart';

class _FakeProJobsRepository extends ProJobsRepository {
  _FakeProJobsRepository({this.onFetch, this.onReturn});

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
  addressText: 'Rua das Flores 20',
  status: 'accepted',
  createdAt: null,
  acceptedAt: null,
  clientId: 'client-1',
);

void main() {
  group('ProJobsController (accepted)', () {
    test('loads accepted jobs', () async {
      final controller = ProJobsController(
        repository: _FakeProJobsRepository(
          onFetch: () async => const [_job],
        ),
      );

      await controller.loadAcceptedJobs();

      expect(controller.acceptedJobs, hasLength(1));
      expect(controller.isLoadingAccepted, isFalse);
      expect(controller.error, isNull);
    });

    test('stores errors and clears stale jobs when loading fails', () async {
      final controller = ProJobsController(
        repository: _FakeProJobsRepository(
          onFetch: () async {
            throw const ProJobsFailure('Could not load accepted jobs');
          },
        ),
      );

      await controller.loadAcceptedJobs();

      expect(controller.acceptedJobs, isEmpty);
      expect(controller.error, 'Could not load accepted jobs');
    });

    test('removes a job after returning it to incoming requests', () async {
      final controller = ProJobsController(
        repository: _FakeProJobsRepository(
          onFetch: () async => const [_job],
          onReturn: (requestId) async {
            expect(requestId, 'job-1');
          },
        ),
      );

      await controller.loadAcceptedJobs();
      final returned = await controller.returnJobToPending('job-1');

      expect(returned, isTrue);
      expect(controller.acceptedJobs, isEmpty);
      expect(controller.error, isNull);
    });

    test('stores errors when returning a job fails', () async {
      final controller = ProJobsController(
        repository: _FakeProJobsRepository(
          onFetch: () async => const [_job],
          onReturn: (_) async {
            throw const ProJobsFailure('Could not release job');
          },
        ),
      );

      await controller.loadAcceptedJobs();
      final returned = await controller.returnJobToPending('job-1');

      expect(returned, isFalse);
      expect(controller.acceptedJobs, hasLength(1));
      expect(controller.error, 'Could not release job');
    });
  });
}
