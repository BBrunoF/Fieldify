import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/client/job_history/controllers/job_history_controller.dart';
import 'package:project/features/client/job_history/data/models/job_history_model.dart';
import 'package:project/features/client/job_history/data/repositories/job_history_repository.dart';

class _FakeJobHistoryRepository extends JobHistoryRepository {
  _FakeJobHistoryRepository({this.onFetch});

  final Future<List<ClientJob>> Function()? onFetch;

  @override
  Future<List<ClientJob>> fetchAllJobs() async {
    return await onFetch?.call() ?? const [];
  }
}

ClientJob _job({required String id, required String status}) {
  return ClientJob.fromJson({
    'id': id,
    'title': 'Job $id',
    'description': '',
    'status': status,
  });
}

void main() {
  group('JobHistoryController', () {
    test('splits jobs into active and past buckets', () async {
      final controller = JobHistoryController(
        repository: _FakeJobHistoryRepository(
          onFetch: () async => [
            _job(id: '1', status: 'pending'),
            _job(id: '2', status: 'completed'),
            _job(id: '3', status: 'accepted'),
            _job(id: '4', status: 'cancelled'),
          ],
        ),
      );

      await controller.loadJobs();

      expect(controller.activeJobs.map((j) => j.id), ['1', '3']);
      expect(controller.pastJobs.map((j) => j.id), ['2', '4']);
      expect(controller.isLoading, isFalse);
      expect(controller.error, isNull);
    });

    test('currentJobs follows the selected tab', () async {
      final controller = JobHistoryController(
        repository: _FakeJobHistoryRepository(
          onFetch: () async => [
            _job(id: '1', status: 'pending'),
            _job(id: '2', status: 'completed'),
          ],
        ),
      );

      await controller.loadJobs();

      expect(controller.currentJobs.single.id, '1');

      controller.selectTab(JobHistoryTab.past);
      expect(controller.currentJobs.single.id, '2');
    });

    test('stores error message and clears job lists on failure', () async {
      final controller = JobHistoryController(
        repository: _FakeJobHistoryRepository(
          onFetch: () async {
            throw const JobHistoryFailure('Could not load jobs');
          },
        ),
      );

      await controller.loadJobs();

      expect(controller.error, 'Could not load jobs');
      expect(controller.activeJobs, isEmpty);
      expect(controller.pastJobs, isEmpty);
    });

    test('clearError resets the error state', () async {
      final controller = JobHistoryController(
        repository: _FakeJobHistoryRepository(
          onFetch: () async {
            throw const JobHistoryFailure('boom');
          },
        ),
      );

      await controller.loadJobs();
      expect(controller.error, isNotNull);

      controller.clearError();
      expect(controller.error, isNull);
    });
  });
}
