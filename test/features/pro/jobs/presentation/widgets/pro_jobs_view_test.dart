import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/accepted_jobs/controllers/accepted_jobs_controller.dart';
import 'package:project/features/pro/accepted_jobs/data/models/accepted_job.dart';
import 'package:project/features/pro/accepted_jobs/data/repositories/accepted_jobs_repository.dart';
import 'package:project/features/pro/incoming_jobs/controllers/incoming_jobs_controller.dart';
import 'package:project/features/pro/incoming_jobs/data/models/incoming_job.dart';
import 'package:project/features/pro/incoming_jobs/data/repositories/incoming_jobs_repository.dart';
import 'package:project/features/pro/jobs/presentation/widgets/pro_jobs_view.dart';

import '../../../../../test_helpers.dart';

class _JobsState {
  bool returnedToIncoming = false;
}

class _FakeIncomingJobsRepository extends IncomingJobsRepository {
  _FakeIncomingJobsRepository([this.state]);

  final _JobsState? state;

  @override
  Future<List<IncomingJob>> fetchIncomingJobs({
    bool includeRejected = false,
  }) async {
    if (state?.returnedToIncoming == true) {
      return const [
        IncomingJob(
          id: 'job-1',
          title: 'Accepted sink job',
          description: 'Install the new sink',
          addressText: 'Rua das Flores 20',
          status: 'pending',
          createdAt: null,
          clientId: 'client-1',
        ),
      ];
    }
    return const [];
  }
}

class _FakeAcceptedJobsRepository extends AcceptedJobsRepository {
  _FakeAcceptedJobsRepository([this.state]);

  final _JobsState? state;

  @override
  Future<List<AcceptedJob>> fetchAcceptedJobs() async {
    if (state?.returnedToIncoming == true) return const [];
    return const [
      AcceptedJob(
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
    final incomingController = IncomingJobsController(
      repository: _FakeIncomingJobsRepository(),
    );
    final acceptedController = AcceptedJobsController(
      repository: _FakeAcceptedJobsRepository(),
    );

    await pumpTestApp(
      tester,
      Scaffold(
        body: ProJobsView(
          incomingJobsController: incomingController,
          acceptedJobsController: acceptedController,
        ),
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
    final incomingController = IncomingJobsController(
      repository: _FakeIncomingJobsRepository(state),
    );
    final acceptedController = AcceptedJobsController(
      repository: _FakeAcceptedJobsRepository(state),
    );

    await pumpTestApp(
      tester,
      Scaffold(
        body: ProJobsView(
          incomingJobsController: incomingController,
          acceptedJobsController: acceptedController,
        ),
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
