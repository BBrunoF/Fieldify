import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/shared/job_detail/controllers/job_detail_controller.dart';
import 'package:project/features/shared/job_detail/data/models/job_detail_model.dart';
import 'package:project/features/shared/job_detail/data/repositories/job_detail_repository.dart';

class _FakeRepo extends JobDetailRepository {
  _FakeRepo({
    this.onFetch,
    this.onCancel,
    this.onSubmitReview,
  });

  final Future<JobDetail> Function(String id, ViewerRole role)? onFetch;
  final Future<void> Function(String id, String? reason)? onCancel;
  final Future<void> Function(
    String jobId,
    String clientId,
    String proId,
    int rating,
    String? comment,
  )? onSubmitReview;

  int fetchCalls = 0;
  int onTheWayCalls = 0;
  int inProgressCalls = 0;
  int completedCalls = 0;
  int cancelCalls = 0;
  int submitReviewCalls = 0;

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

  @override
  Future<void> submitReview({
    required String jobId,
    required String clientId,
    required String proId,
    required int rating,
    String? comment,
  }) {
    submitReviewCalls++;
    return onSubmitReview?.call(jobId, clientId, proId, rating, comment) ??
        Future.value();
  }
}

JobDetail _detail(
  String id, {
  String status = 'pending',
  String? proId,
  Map<String, dynamic>? reviewRow,
}) =>
    JobDetail.fromJson(
      jobRow: {
        'id': id,
        'title': 'Test job',
        'description': '',
        'address_text': '',
        'status': status,
        'client_id': 'c1',
        'pro_id': proId,
        'trade_id': 1,
        'trades': {'id': 1, 'display_name': 'General', 'standard_rate': 0},
        'created_at': '2026-04-10T09:00:00Z',
      },
      counterpartyRow: null,
      viewerRole: ViewerRole.client,
      photoUrls: const [],
      reviewRow: reviewRow,
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

  group('Client submitReview', () {
    Map<String, dynamic> reviewRow({int rating = 5, String? comment}) => {
          'id': 'r1',
          'request_id': 'j1',
          'client_id': 'c1',
          'pro_id': 'p1',
          'rating': rating,
          'comment': comment,
          'created_at': '2026-04-11T09:00:00Z',
        };

    test('submits review and refetches when valid', () async {
      var fetched = 0;
      String? capturedComment;
      int? capturedRating;

      final repo = _FakeRepo(
        onFetch: (id, _) async {
          fetched++;
          return _detail(
            id,
            status: 'completed',
            proId: 'p1',
            reviewRow: fetched == 1 ? null : reviewRow(comment: 'great'),
          );
        },
        onSubmitReview: (_, _, _, rating, comment) async {
          capturedRating = rating;
          capturedComment = comment;
        },
      );

      final controller = JobDetailController(
        jobId: 'j1',
        viewerRole: ViewerRole.client,
        repo: repo,
      );
      await controller.load();

      await controller.submitReview(rating: 5, comment: 'great');

      expect(repo.submitReviewCalls, 1);
      expect(capturedRating, 5);
      expect(capturedComment, 'great');
      expect(controller.detail?.review?.rating, 5);
      expect(controller.detail?.review?.comment, 'great');
    });

    test('is a no-op when job is not completed', () async {
      final repo = _FakeRepo(
        onFetch: (id, _) async =>
            _detail(id, status: 'in_progress', proId: 'p1'),
      );
      final controller = JobDetailController(
        jobId: 'j1',
        viewerRole: ViewerRole.client,
        repo: repo,
      );
      await controller.load();

      await controller.submitReview(rating: 4);
      expect(repo.submitReviewCalls, 0);
    });

    test('is a no-op when viewer is pro', () async {
      final repo = _FakeRepo(
        onFetch: (id, _) async =>
            _detail(id, status: 'completed', proId: 'p1'),
      );
      final controller = JobDetailController(
        jobId: 'j1',
        viewerRole: ViewerRole.pro,
        repo: repo,
      );
      await controller.load();

      await controller.submitReview(rating: 4);
      expect(repo.submitReviewCalls, 0);
    });

    test('is a no-op when a review already exists', () async {
      final repo = _FakeRepo(
        onFetch: (id, _) async => _detail(
          id,
          status: 'completed',
          proId: 'p1',
          reviewRow: reviewRow(),
        ),
      );
      final controller = JobDetailController(
        jobId: 'j1',
        viewerRole: ViewerRole.client,
        repo: repo,
      );
      await controller.load();

      await controller.submitReview(rating: 3);
      expect(repo.submitReviewCalls, 0);
    });

    test('rejects ratings outside 1..5 without calling repo', () async {
      final repo = _FakeRepo(
        onFetch: (id, _) async =>
            _detail(id, status: 'completed', proId: 'p1'),
      );
      final controller = JobDetailController(
        jobId: 'j1',
        viewerRole: ViewerRole.client,
        repo: repo,
      );
      await controller.load();

      await controller.submitReview(rating: 0);
      expect(repo.submitReviewCalls, 0);
      expect(controller.error, isNotNull);

      await controller.submitReview(rating: 6);
      expect(repo.submitReviewCalls, 0);
    });

    test('exposes JobDetailFailure message on submit error', () async {
      final repo = _FakeRepo(
        onFetch: (id, _) async =>
            _detail(id, status: 'completed', proId: 'p1'),
        onSubmitReview: (_, _, _, _, _) async =>
            throw const JobDetailFailure('rls blocked'),
      );
      final controller = JobDetailController(
        jobId: 'j1',
        viewerRole: ViewerRole.client,
        repo: repo,
      );
      await controller.load();

      await controller.submitReview(rating: 5);
      expect(controller.error, 'rls blocked');
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
