import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/accepted_jobs/controllers/accepted_jobs_controller.dart';
import 'package:project/features/pro/accepted_jobs/data/models/accepted_job.dart';
import 'package:project/features/pro/accepted_jobs/data/repositories/accepted_jobs_repository.dart';
import 'package:project/features/pro/accepted_jobs/presentation/widgets/accepted_jobs_view.dart';

import '../../../../../test_helpers.dart';

class _FakeAcceptedJobsRepository extends AcceptedJobsRepository {
  _FakeAcceptedJobsRepository({this.onFetch});

  final Future<List<AcceptedJob>> Function()? onFetch;

  @override
  Future<List<AcceptedJob>> fetchAcceptedJobs() async {
    return await onFetch?.call() ?? const [];
  }
}

AcceptedJob _job() {
  return AcceptedJob(
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
      final controller = AcceptedJobsController(
        repository: _FakeAcceptedJobsRepository(onFetch: () async => const []),
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
      final controller = AcceptedJobsController(
        repository: _FakeAcceptedJobsRepository(onFetch: () async => [_job()]),
      );

      await pumpTestApp(
        tester,
        Scaffold(body: AcceptedJobsView(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('acceptedJobsList')), findsOneWidget);
      expect(find.text('Pipe leak'), findsOneWidget);
      expect(find.text('On my way'), findsOneWidget);
      expect(find.text('Accept'), findsNothing);
      expect(find.text('Reject'), findsNothing);
    });
  });
}
