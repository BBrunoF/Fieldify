import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/client/job_history/data/models/job_history_model.dart';
import 'package:project/features/client/job_history/data/repositories/job_history_repository.dart';
import 'package:project/features/client/job_history/data/services/job_history_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeJobHistoryService extends JobHistoryService {
  _FakeJobHistoryService({this.onFetch});

  final Future<List<ClientJob>> Function()? onFetch;

  @override
  Future<List<ClientJob>> fetchAllJobs() async {
    return await onFetch?.call() ?? const [];
  }
}

void main() {
  group('JobHistoryRepository', () {
    test('returns jobs produced by the service on success', () async {
      final job = ClientJob.fromJson({
        'id': 'j1',
        'title': 'Work',
        'description': '',
        'status': 'pending',
      });

      final repository = JobHistoryRepository(
        service: _FakeJobHistoryService(onFetch: () async => [job]),
      );

      final result = await repository.fetchAllJobs();

      expect(result, hasLength(1));
      expect(result.single.id, 'j1');
    });

    test('wraps PostgrestException into JobHistoryFailure', () async {
      final repository = JobHistoryRepository(
        service: _FakeJobHistoryService(
          onFetch: () async {
            throw PostgrestException(message: 'db offline');
          },
        ),
      );

      await expectLater(
        repository.fetchAllJobs,
        throwsA(
          isA<JobHistoryFailure>().having(
            (error) => error.message,
            'message',
            'db offline',
          ),
        ),
      );
    });

    test('lets other exceptions bubble up unchanged', () async {
      final repository = JobHistoryRepository(
        service: _FakeJobHistoryService(
          onFetch: () async {
            throw const AuthException('No authenticated user.');
          },
        ),
      );

      await expectLater(
        repository.fetchAllJobs,
        throwsA(isA<AuthException>()),
      );
    });
  });
}
