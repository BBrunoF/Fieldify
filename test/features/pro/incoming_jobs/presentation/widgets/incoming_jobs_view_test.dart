import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/incoming_jobs/controllers/incoming_jobs_controller.dart';
import 'package:project/features/pro/incoming_jobs/data/models/incoming_job.dart';
import 'package:project/features/pro/incoming_jobs/data/repositories/incoming_jobs_repository.dart';
import 'package:project/features/pro/incoming_jobs/presentation/widgets/incoming_jobs_view.dart';

import '../../../../../test_helpers.dart';

class _FakeIncomingJobsRepository extends IncomingJobsRepository {
  _FakeIncomingJobsRepository({this.onFetch, this.onReject});

  final Future<List<IncomingJob>> Function({required bool includeRejected})?
  onFetch;
  final Future<void> Function(String requestId)? onReject;

  @override
  Future<List<IncomingJob>> fetchIncomingJobs({
    bool includeRejected = false,
  }) async {
    return await onFetch?.call(includeRejected: includeRejected) ?? const [];
  }

  @override
  Future<void> rejectJob(String requestId) async {
    await onReject?.call(requestId);
  }
}

IncomingJob _job({bool isRejected = false}) {
  return IncomingJob(
    id: 'job-1',
    title: 'Pipe leak',
    description: 'Water dripping under the sink',
    addressText: 'Rua das Flores 20',
    status: 'pending',
    createdAt: null,
    clientId: 'client-1',
    isRejected: isRejected,
  );
}

void main() {
  group('IncomingJobsView', () {
    testWidgets('shows the empty state when no jobs are available', (
      tester,
    ) async {
      final controller = IncomingJobsController(
        repository: _FakeIncomingJobsRepository(
          onFetch: ({required includeRejected}) async => const [],
        ),
      );

      await pumpTestApp(
        tester,
        Scaffold(body: IncomingJobsView(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('incomingJobsEmptyState')), findsOneWidget);
      expect(find.text('No pending jobs right now.'), findsOneWidget);
    });

    testWidgets('removes a job from the list after rejection', (tester) async {
      final controller = IncomingJobsController(
        repository: _FakeIncomingJobsRepository(
          onFetch: ({required includeRejected}) async => [_job()],
          onReject: (requestId) async {},
        ),
      );

      await pumpTestApp(
        tester,
        Scaffold(body: IncomingJobsView(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pipe leak'), findsOneWidget);

      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('incomingJobsEmptyState')), findsOneWidget);
    });

    testWidgets('shows a snackbar when loading fails', (tester) async {
      final controller = IncomingJobsController(
        repository: _FakeIncomingJobsRepository(
          onFetch: ({required includeRejected}) async {
            throw const IncomingJobsFailure('Could not load jobs');
          },
        ),
      );

      await pumpTestApp(
        tester,
        Scaffold(body: IncomingJobsView(controller: controller)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Could not load jobs'), findsOneWidget);
    });
  });
}
