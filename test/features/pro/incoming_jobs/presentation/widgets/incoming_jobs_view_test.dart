import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/jobs/controllers/pro_jobs_controller.dart';
import 'package:project/features/pro/jobs/data/models/pro_job.dart';
import 'package:project/features/pro/jobs/data/repositories/pro_jobs_repository.dart';
import 'package:project/features/pro/jobs/presentation/widgets/incoming_jobs_view.dart';

import '../../../../../test_helpers.dart';

class _FakeProJobsRepository extends ProJobsRepository {
  _FakeProJobsRepository({this.onFetch, this.onReject});

  final Future<List<ProJob>> Function({required bool includeRejected})? onFetch;
  final Future<void> Function(String requestId)? onReject;

  @override
  Future<List<ProJob>> fetchIncomingJobs({
    bool includeRejected = false,
  }) async {
    return await onFetch?.call(includeRejected: includeRejected) ?? const [];
  }

  @override
  Future<void> rejectJob(String requestId) async {
    await onReject?.call(requestId);
  }
}

ProJob _job({bool isRejected = false}) {
  return ProJob(
    id: 'job-1',
    title: 'Pipe leak',
    description: 'Water dripping under the sink',
    addressText: 'Rua das Flores 20',
    status: 'pending',
    createdAt: null,
    acceptedAt: null,
    clientId: 'client-1',
    isRejected: isRejected,
  );
}

void main() {
  group('IncomingJobsView', () {
    testWidgets('shows the empty state when no jobs are available', (
      tester,
    ) async {
      final controller = ProJobsController(
        repository: _FakeProJobsRepository(
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
      final controller = ProJobsController(
        repository: _FakeProJobsRepository(
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
      final controller = ProJobsController(
        repository: _FakeProJobsRepository(
          onFetch: ({required includeRejected}) async {
            throw const ProJobsFailure('Could not load jobs');
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
