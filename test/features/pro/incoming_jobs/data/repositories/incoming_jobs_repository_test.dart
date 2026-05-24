import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/jobs/data/models/pro_job.dart';
import 'package:project/features/pro/jobs/data/repositories/pro_jobs_repository.dart';
import 'package:project/features/pro/jobs/data/services/pro_jobs_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeProJobsService extends ProJobsService {
  _FakeProJobsService({this.onFetch, this.onAccept, this.onReject});

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

void main() {
  group('ProJobsRepository (incoming)', () {
    test(
      'maps missing professional profile errors into ProJobsFailure',
      () async {
        final repository = ProJobsRepository(
          service: _FakeProJobsService(
            onFetch: ({required includeRejected}) async {
              throw const ProfessionalProfileMissingException();
            },
          ),
        );

        await expectLater(
          repository.fetchIncomingJobs,
          throwsA(
            isA<ProJobsFailure>().having(
              (error) => error.message,
              'message',
              'Professional profile not set up.',
            ),
          ),
        );
      },
    );

    test('maps already-taken errors into ProJobsFailure', () async {
      final repository = ProJobsRepository(
        service: _FakeProJobsService(
          onAccept: (requestId) async {
            throw const JobAlreadyTakenException();
          },
        ),
      );

      await expectLater(
        () => repository.acceptJob('job-1'),
        throwsA(
          isA<ProJobsFailure>().having(
            (error) => error.message,
            'message',
            'Job already taken by another professional.',
          ),
        ),
      );
    });

    test('maps Postgrest errors from rejectJob into ProJobsFailure', () async {
      final repository = ProJobsRepository(
        service: _FakeProJobsService(
          onReject: (requestId) async {
            throw const PostgrestException(message: 'Permission denied');
          },
        ),
      );

      await expectLater(
        () => repository.rejectJob('job-1'),
        throwsA(
          isA<ProJobsFailure>().having(
            (error) => error.message,
            'message',
            'Permission denied',
          ),
        ),
      );
    });
  });
}
