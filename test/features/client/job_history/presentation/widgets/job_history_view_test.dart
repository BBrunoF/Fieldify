import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/client/job_history/controllers/job_history_controller.dart';
import 'package:project/features/client/job_history/data/models/job_history_model.dart';
import 'package:project/features/client/job_history/data/repositories/job_history_repository.dart';
import 'package:project/features/client/job_history/presentation/widgets/job_history_view.dart';

import '../../../../../test_helpers.dart';

class _FakeJobHistoryRepository extends JobHistoryRepository {
  _FakeJobHistoryRepository({this.onFetch});

  final Future<List<ClientJob>> Function()? onFetch;

  @override
  Future<List<ClientJob>> fetchAllJobs() async {
    return await onFetch?.call() ?? const [];
  }
}

ClientJob _job({required String id, required String status, String title = 'Job'}) {
  return ClientJob.fromJson({
    'id': id,
    'title': title,
    'description': '',
    'status': status,
  });
}

void main() {
  group('JobHistoryView', () {
    testWidgets('shows the empty state when there are no active jobs', (
      tester,
    ) async {
      final controller = JobHistoryController(
        repository: _FakeJobHistoryRepository(onFetch: () async => const []),
      );

      await pumpTestApp(
        tester,
        Scaffold(body: JobHistoryView(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('jobHistoryEmptyState')), findsOneWidget);
      expect(find.text('No active jobs right now.'), findsOneWidget);
    });

    testWidgets('switches to the past tab and lists past jobs', (tester) async {
      final controller = JobHistoryController(
        repository: _FakeJobHistoryRepository(
          onFetch: () async => [
            _job(id: '1', status: 'pending', title: 'Active one'),
            _job(id: '2', status: 'completed', title: 'Old one'),
          ],
        ),
      );

      await pumpTestApp(
        tester,
        Scaffold(body: JobHistoryView(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active one'), findsOneWidget);
      expect(find.text('Old one'), findsNothing);

      await tester.tap(find.byKey(const Key('jobHistoryTabPast')));
      await tester.pumpAndSettle();

      expect(find.text('Old one'), findsOneWidget);
      expect(find.text('Active one'), findsNothing);
    });

    testWidgets('shows a snackbar when loading fails', (tester) async {
      final controller = JobHistoryController(
        repository: _FakeJobHistoryRepository(
          onFetch: () async {
            throw const JobHistoryFailure('Could not load jobs');
          },
        ),
      );

      await pumpTestApp(
        tester,
        Scaffold(body: JobHistoryView(controller: controller)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Could not load jobs'), findsOneWidget);
    });
  });
}
