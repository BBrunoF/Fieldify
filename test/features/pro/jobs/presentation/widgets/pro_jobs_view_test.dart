import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/jobs/controllers/pro_jobs_controller.dart';
import 'package:project/features/pro/jobs/data/models/pro_job.dart';
import 'package:project/features/pro/jobs/data/repositories/pro_jobs_repository.dart';
import 'package:project/features/pro/jobs/presentation/widgets/pro_jobs_view.dart';

import '../../../../../test_helpers.dart';

class _JobsState {
  bool returnedToIncoming = false;
}

class _FakeProJobsRepository extends ProJobsRepository {
  _FakeProJobsRepository([this.state]);

  final _JobsState? state;

  @override
  Future<List<ProJob>> fetchIncomingJobs({
    bool includeRejected = false,
  }) async {
    if (state?.returnedToIncoming == true) {
      return const [
        ProJob(
          id: 'job-1',
          title: 'Accepted sink job',
          description: 'Install the new sink',
          addressText: 'Rua das Flores 20',
          status: 'pending',
          createdAt: null,
          acceptedAt: null,
          clientId: 'client-1',
        ),
      ];
    }
    return const [];
  }

  @override
  Future<List<ProJob>> fetchAcceptedJobs() async {
    if (state?.returnedToIncoming == true) return const [];
    return const [
      ProJob(
        id: 'job-1',
        title: 'Accepted sink job',
        description: 'Install the new sink',
        addressText: 'Rua das Flores 20',
        status: 'accepted',
        createdAt: null,
        acceptedAt: null,
        clientId: 'client-1',
      ),
    ];
  }

  @override
  Future<void> returnJobToPending(String requestId) async {
    state?.returnedToIncoming = true;
  }
}

void main() {
  testWidgets('switches between incoming and accepted job tabs', (
    tester,
  ) async {
    final controller = ProJobsController(
      repository: _FakeProJobsRepository(),
    );

    await pumpTestApp(
      tester,
      Scaffold(
        body: ProJobsView(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('incomingJobsView')), findsOneWidget);
    expect(find.text('Accepted sink job'), findsNothing);

    await tester.tap(find.byKey(const Key('proJobsTabAccepted')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('acceptedJobsList')), findsOneWidget);
    expect(find.text('Accepted sink job'), findsOneWidget);
  });

  testWidgets('returning an accepted job refreshes the incoming tab', (
    tester,
  ) async {
    final state = _JobsState();
    final controller = ProJobsController(
      repository: _FakeProJobsRepository(state),
    );

    await pumpTestApp(
      tester,
      Scaffold(
        body: ProJobsView(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('proJobsTabAccepted')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel job'));
    await tester.pumpAndSettle();

    expect(find.text('Accepted sink job'), findsNothing);

    await tester.tap(find.byKey(const Key('proJobsTabIncoming')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('incomingJobsList')), findsOneWidget);
    expect(find.text('Accepted sink job'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
  });
}
