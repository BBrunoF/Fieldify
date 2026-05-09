import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/shared/job_detail/data/models/job_detail_model.dart';
import 'package:project/features/shared/job_detail/data/repositories/job_detail_repository.dart';
import 'package:project/features/shared/job_detail/data/services/job_detail_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeJobDetailService extends JobDetailService {
  _FakeJobDetailService({
    this.onFetch,
    this.onMarkOnTheWay,
    this.onCancel,
  });

  final Future<JobDetail> Function(String id, ViewerRole role)? onFetch;
  final Future<void> Function(String id)? onMarkOnTheWay;
  final Future<void> Function(String id, String? reason)? onCancel;

  @override
  Future<JobDetail> fetchJobDetail(String jobId, ViewerRole viewerRole) =>
      onFetch?.call(jobId, viewerRole) ??
      Future.error(StateError('not stubbed'));

  @override
  Future<void> markOnTheWay(String jobId) =>
      onMarkOnTheWay?.call(jobId) ?? Future.value();

  @override
  Future<void> markInProgress(String jobId) => Future.value();

  @override
  Future<void> markCompleted(String jobId) => Future.value();

  @override
  Future<void> cancelJob(String jobId, {String? reason}) =>
      onCancel?.call(jobId, reason) ?? Future.value();
}

JobDetail _detail(String id) => JobDetail.fromJson(
      jobRow: {
        'id': id,
        'title': 'x',
        'description': '',
        'address_text': '',
        'status': 'pending',
        'client_id': 'c1',
        'pro_id': null,
        'trade_id': 1,
        'trades': {'id': 1, 'display_name': 'g', 'standard_rate': 0},
        'created_at': '2026-04-10T09:00:00Z',
      },
      counterpartyRow: null,
      viewerRole: ViewerRole.client,
      photoUrls: const [],
    );

void main() {
  group('JobDetailRepository', () {
    test('fetchJobDetail returns the service result', () async {
      final repo = JobDetailRepository(
        service: _FakeJobDetailService(
          onFetch: (id, _) async => _detail(id),
        ),
      );

      final result = await repo.fetchJobDetail('j1', ViewerRole.client);
      expect(result.id, 'j1');
    });

    test('fetchJobDetail wraps PostgrestException into JobDetailFailure',
        () async {
      final repo = JobDetailRepository(
        service: _FakeJobDetailService(
          onFetch: (_, _) async =>
              throw PostgrestException(message: 'db offline'),
        ),
      );

      await expectLater(
        () => repo.fetchJobDetail('j1', ViewerRole.client),
        throwsA(isA<JobDetailFailure>()
            .having((e) => e.message, 'message', 'db offline')),
      );
    });

    test('fetchJobDetail wraps StorageException into JobDetailFailure',
        () async {
      final repo = JobDetailRepository(
        service: _FakeJobDetailService(
          onFetch: (_, _) async =>
              throw const StorageException('signed-url failed'),
        ),
      );

      await expectLater(
        () => repo.fetchJobDetail('j1', ViewerRole.client),
        throwsA(isA<JobDetailFailure>()
            .having((e) => e.message, 'message', 'signed-url failed')),
      );
    });

    test('cancelJob passes through the reason parameter', () async {
      String? captured;
      final repo = JobDetailRepository(
        service: _FakeJobDetailService(
          onCancel: (id, reason) async {
            captured = reason;
          },
        ),
      );

      await repo.cancelJob('j1', reason: 'changed my mind');
      expect(captured, 'changed my mind');
    });

    test('status transitions wrap errors into JobDetailFailure', () async {
      final repo = JobDetailRepository(
        service: _FakeJobDetailService(
          onMarkOnTheWay: (_) async =>
              throw PostgrestException(message: 'rls blocked'),
        ),
      );

      await expectLater(
        () => repo.markOnTheWay('j1'),
        throwsA(isA<JobDetailFailure>()),
      );
    });
  });
}
