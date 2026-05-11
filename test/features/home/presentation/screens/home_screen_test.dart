import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/home/presentation/screens/home_screen.dart';
import 'package:project/features/pro/jobs/controllers/pro_jobs_controller.dart';
import 'package:project/features/pro/jobs/data/models/pro_job.dart';
import 'package:project/features/pro/jobs/data/repositories/pro_jobs_repository.dart';

import '../../../../test_helpers.dart';

class _FakeProJobsRepository extends ProJobsRepository {
  @override
  Future<List<ProJob>> fetchIncomingJobs({
    bool includeRejected = false,
  }) async {
    return const [];
  }
}

void main() {
  group('HomeScreen', () {
    testWidgets('client users see jobs tab and can open request flow', (
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

      expect(find.byKey(const Key('bottomNavItem_jobs')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('goToRequestButton')));
      await tester.tap(find.byKey(const Key('goToRequestButton')));
      await tester.pumpAndSettle();

      expect(find.text('Fake request'), findsOneWidget);
    });

    testWidgets('professional users can open the incoming jobs tab', (
      tester,
    ) async {
      final controller = ProJobsController(
        repository: _FakeProJobsRepository(),
      );

      await pumpTestApp(
        tester,
        HomeScreen(
          loadProfessionalRole: () async => true,
          proJobsController: controller,
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
