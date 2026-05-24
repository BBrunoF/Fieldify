import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/jobs/controllers/pro_jobs_controller.dart';
import 'package:project/features/pro/jobs/data/models/pro_job.dart';
import 'package:project/features/pro/jobs/data/repositories/pro_jobs_repository.dart';
import 'package:project/features/pro/jobs/presentation/widgets/accepted_jobs_view.dart';

import '../../../../../test_helpers.dart';

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

ProJob _job() {
  return ProJob(
    id: 'job-1',
    title: 'Pipe leak',
    description: 'Water dripping under the sink',
    addressText: 'Rua das Flores 20',
    status: 'on_my_way',
    createdAt: null,
    acceptedAt: DateTime.parse('2026-04-21T09:45:00.000Z'),
    clientId: 'client-1',
  );
}

void main() {
  group('AcceptedJobsView', () {
    testWidgets('shows the empty state when no accepted jobs are available', (
      tester,
    ) async {
      final controller = ProJobsController(
        repository: _FakeProJobsRepository(onFetch: () async => const []),
      );

      await pumpTestApp(
        tester,
        Scaffold(body: AcceptedJobsView(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('acceptedJobsEmptyState')), findsOneWidget);
      expect(find.text('No accepted jobs right now.'), findsOneWidget);
    });

    testWidgets('renders accepted jobs without incoming job actions', (
      tester,
    ) async {
      final controller = ProJobsController(
        repository: _FakeProJobsRepository(onFetch: () async => [_job()]),
      );

      await pumpTestApp(
        tester,
        Scaffold(body: AcceptedJobsView(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('acceptedJobsList')), findsOneWidget);
      expect(find.text('Pipe leak'), findsOneWidget);
      expect(find.text('On my way'), findsOneWidget);
      expect(find.text('Cancel job'), findsOneWidget);
      expect(find.text('Accept'), findsNothing);
      expect(find.text('Reject'), findsNothing);
    });

    testWidgets('returns accepted jobs to incoming and removes them', (
      tester,
    ) async {
      var callbackCalled = false;
      final controller = ProJobsController(
        repository: _FakeProJobsRepository(
          onFetch: () async => [_job()],
          onReturn: (requestId) async {
            expect(requestId, 'job-1');
          },
        ),
      );

      await pumpTestApp(
        tester,
        Scaffold(
          body: AcceptedJobsView(
            controller: controller,
            onJobReturnedToIncoming: () => callbackCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel job'));
      await tester.pumpAndSettle();

      expect(callbackCalled, isTrue);
      expect(find.byKey(const Key('acceptedJobsEmptyState')), findsOneWidget);
      expect(find.text('Pipe leak'), findsNothing);
    });
  });
}
