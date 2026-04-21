import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/home/presentation/screens/home_screen.dart';
import 'package:project/features/pro/incoming_jobs/controllers/incoming_jobs_controller.dart';
import 'package:project/features/pro/incoming_jobs/data/models/incoming_job.dart';
import 'package:project/features/pro/incoming_jobs/data/repositories/incoming_jobs_repository.dart';

import '../../../../test_helpers.dart';

class _FakeIncomingJobsRepository extends IncomingJobsRepository {
  @override
  Future<List<IncomingJob>> fetchIncomingJobs({
    bool includeRejected = false,
  }) async {
    return const [];
  }
}

void main() {
  group('HomeScreen', () {
    testWidgets('client users do not see jobs tab and can open request flow', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        HomeScreen(
          loadProfessionalRole: () async => false,
          requestScreenBuilder: (_) =>
              const Scaffold(body: Text('Fake request')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bottomNavItem_jobs')), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('goToRequestButton')));
      await tester.tap(find.byKey(const Key('goToRequestButton')));
      await tester.pumpAndSettle();

      expect(find.text('Fake request'), findsOneWidget);
    });

    testWidgets('professional users can open the incoming jobs tab', (
      tester,
    ) async {
      final controller = IncomingJobsController(
        repository: _FakeIncomingJobsRepository(),
      );

      await pumpTestApp(
        tester,
        HomeScreen(
          loadProfessionalRole: () async => true,
          incomingJobsController: controller,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bottomNavItem_jobs')), findsOneWidget);

      await tester.tap(find.byKey(const Key('bottomNavItem_jobs')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('homeJobsTab')), findsOneWidget);
      expect(find.byKey(const Key('incomingJobsView')), findsOneWidget);
    });
  });
}
