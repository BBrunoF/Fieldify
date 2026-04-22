import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/incoming_jobs/data/models/incoming_job.dart';
import 'package:project/features/pro/incoming_jobs/data/repositories/incoming_jobs_repository.dart';
import 'package:project/features/pro/incoming_jobs/data/services/incoming_jobs_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeIncomingJobsService extends IncomingJobsService {
  _FakeIncomingJobsService({this.onFetch, this.onAccept, this.onReject});

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

void main() {
  group('IncomingJobsRepository', () {
    test(
      'maps missing professional profile errors into IncomingJobsFailure',
      () async {
        final repository = IncomingJobsRepository(
          service: _FakeIncomingJobsService(
            onFetch: ({required includeRejected}) async {
              throw const ProfessionalProfileMissingException();
            },
          ),
        );

        await expectLater(
          repository.fetchIncomingJobs,
          throwsA(
            isA<IncomingJobsFailure>().having(
              (error) => error.message,
              'message',
              'Professional profile not set up.',
            ),
          ),
        );
      },
    );

    test('maps already-taken errors into IncomingJobsFailure', () async {
      final repository = IncomingJobsRepository(
        service: _FakeIncomingJobsService(
          onAccept: (requestId) async {
            throw const JobAlreadyTakenException();
          },
        ),
      );

      await expectLater(
        () => repository.acceptJob('job-1'),
        throwsA(
          isA<IncomingJobsFailure>().having(
            (error) => error.message,
            'message',
            'Job already taken by another professional.',
          ),
        ),
      );
    });

    test(
      'maps Postgrest errors from rejectJob into IncomingJobsFailure',
      () async {
        final repository = IncomingJobsRepository(
          service: _FakeIncomingJobsService(
            onReject: (requestId) async {
              throw const PostgrestException(message: 'Permission denied');
            },
          ),
        );

        await expectLater(
          () => repository.rejectJob('job-1'),
          throwsA(
            isA<IncomingJobsFailure>().having(
              (error) => error.message,
              'message',
              'Permission denied',
            ),
          ),
        );
      },
    );
  });
}
