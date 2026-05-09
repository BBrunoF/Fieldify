import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/shared/job_detail/controllers/job_detail_controller.dart';
import 'package:project/features/shared/job_detail/data/models/job_detail_model.dart';
import 'package:project/features/shared/job_detail/data/repositories/job_detail_repository.dart';

class _FakeRepo extends JobDetailRepository {
  _FakeRepo({
    this.onFetch,
    this.onCancel,
  });

  final Future<JobDetail> Function(String id, ViewerRole role)? onFetch;
  final Future<void> Function(String id, String? reason)? onCancel;

  int fetchCalls = 0;
  int onTheWayCalls = 0;
  int inProgressCalls = 0;
  int completedCalls = 0;
  int cancelCalls = 0;

  @override
  Future<JobDetail> fetchJobDetail(String jobId, ViewerRole viewerRole) {
    fetchCalls++;
    return onFetch?.call(jobId, viewerRole) ??
        Future.error(StateError('not stubbed'));
  }

  @override
  Future<void> markOnTheWay(String jobId) {
    onTheWayCalls++;
    return Future.value();
  }

  @override
  Future<void> markInProgress(String jobId) {
    inProgressCalls++;
    return Future.value();
  }

  @override
  Future<void> markCompleted(String jobId) {
    completedCalls++;
    return Future.value();
  }

  @override
  Future<void> cancelJob(String jobId, {String? reason}) {
    cancelCalls++;
    return onCancel?.call(jobId, reason) ?? Future.value();
  }
}

JobDetail _detail(String id, {String status = 'pending'}) =>
    JobDetail.fromJson(
      jobRow: {
        'id': id,
        'title': 'Test job',
        'description': '',
        'address_text': '',
        'status': status,
        'client_id': 'c1',
        'pro_id': null,
        'trade_id': 1,
        'trades': {'id': 1, 'display_name': 'General', 'standard_rate': 0},
        'created_at': '2026-04-10T09:00:00Z',
      },
      counterpartyRow: null,
      viewerRole: ViewerRole.client,
      photoUrls: const [],
    );

void main() {
  group('JobDetailController.load', () {
    test('populates detail on success', () async {
      final controller = JobDetailController(
        jobId: 'j1',
        viewerRole: ViewerRole.client,
        repo: _FakeRepo(onFetch: (id, _) async => _detail(id)),
      );

      await controller.load();

      expect(controller.detail?.id, 'j1');
      expect(controller.isLoading, isFalse);
      expect(controller.error, isNull);
    });

    test('captures JobDetailFailure message as error', () async {
      final controller = JobDetailController(
        jobId: 'j1',
        viewerRole: ViewerRole.client,
        repo: _FakeRepo(
          onFetch: (_, _) async => throw const JobDetailFailure('nope'),
        ),
      );

      await controller.load();
      expect(controller.error, 'nope');
      expect(controller.detail, isNull);
    });

    test('uses generic fallback message for unexpected errors', () async {
      final controller = JobDetailController(
        jobId: 'j1',
        viewerRole: ViewerRole.client,
        repo: _FakeRepo(onFetch: (_, _) async => throw StateError('boom')),
      );

      await controller.load();
      expect(controller.error, 'Could not load job.');
    });
  });

  group('Pro-only transitions', () {
    test('markOnTheWay runs and refreshes when viewer is pro', () async {
      final repo = _FakeRepo(
        onFetch: (id, _) async => _detail(id, status: 'on_the_way'),
      );
      final controller = JobDetailController(
        jobId: 'j1',
        viewerRole: ViewerRole.pro,
        repo: repo,
      );

      await controller.markOnTheWay();

      expect(repo.onTheWayCalls, 1);
      expect(repo.fetchCalls, 1); // refetch after mutation
      expect(controller.detail?.status, JobStatus.onMyWay);
    });

    test('pro-only methods are no-ops when viewer is client', () async {
      final repo = _FakeRepo();
      final controller = JobDetailController(
        jobId: 'j1',
        viewerRole: ViewerRole.client,
        repo: repo,
      );

      await controller.markOnTheWay();
      await controller.markInProgress();
      await controller.markCompleted();

      expect(repo.onTheWayCalls, 0);
      expect(repo.inProgressCalls, 0);
      expect(repo.completedCalls, 0);
      expect(repo.fetchCalls, 0);
    });
  });

  group('Client cancel', () {
    test('calls repo and refetches when viewer is client', () async {
      final repo = _FakeRepo(
        onFetch: (id, _) async => _detail(id, status: 'cancelled'),
      );
      final controller = JobDetailController(
        jobId: 'j1',
        viewerRole: ViewerRole.client,
        repo: repo,
      );

      await controller.cancel(reason: 'oops');

      expect(repo.cancelCalls, 1);
      expect(repo.fetchCalls, 1);
      expect(controller.detail?.status, JobStatus.cancelled);
    });

    test('is a no-op when viewer is pro', () async {
      final repo = _FakeRepo();
      final controller = JobDetailController(
        jobId: 'j1',
        viewerRole: ViewerRole.pro,
        repo: repo,
      );

      await controller.cancel();
      expect(repo.cancelCalls, 0);
    });

    test('exposes JobDetailFailure message on mutation error', () async {
      final repo = _FakeRepo(
        onCancel: (_, _) async => throw const JobDetailFailure('rls blocked'),
      );
      final controller = JobDetailController(
        jobId: 'j1',
        viewerRole: ViewerRole.client,
        repo: repo,
      );

      await controller.cancel();
      expect(controller.error, 'rls blocked');
      expect(controller.isPerformingAction, isFalse);
    });
  });

  test('re-entrant action calls are dropped', () async {
    var completed = 0;
    final repo = _FakeRepo(
      onCancel: (_, _) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        completed++;
      },
      onFetch: (id, _) async => _detail(id, status: 'cancelled'),
    );
    final controller = JobDetailController(
      jobId: 'j1',
      viewerRole: ViewerRole.client,
      repo: repo,
    );

    final first = controller.cancel();
    final second = controller.cancel(); // should be dropped
    await Future.wait([first, second]);

    expect(completed, 1);
    expect(repo.cancelCalls, 1);
  });
}
