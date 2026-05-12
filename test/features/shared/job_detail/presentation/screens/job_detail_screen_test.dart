import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/shared/job_detail/controllers/job_detail_controller.dart';
import 'package:project/features/shared/job_detail/data/models/job_detail_model.dart';
import 'package:project/features/shared/job_detail/data/repositories/job_detail_repository.dart';
import 'package:project/features/shared/job_detail/presentation/screens/job_detail_screen.dart';

import '../../../../../test_helpers.dart';

class _FakeRepo extends JobDetailRepository {
  _FakeRepo({required this.detail});
  final JobDetail detail;

  @override
  Future<JobDetail> fetchJobDetail(String jobId, ViewerRole role) async => detail;

  @override
  Future<void> markOnTheWay(String jobId) async {}
  @override
  Future<void> markInProgress(String jobId) async {}
  @override
  Future<void> markCompleted(String jobId) async {}
  @override
  Future<void> cancelJob(String jobId, {String? reason}) async {}
}

JobDetail _detail({
  required String status,
  required ViewerRole role,
  String title = 'Leaking pipe',
  List<String> photoUrls = const [],
  Map<String, dynamic>? counterparty,
  Map<String, dynamic>? reviewRow,
}) {
  return JobDetail.fromJson(
    jobRow: {
      'id': 'j1',
      'title': title,
      'description': 'something wrong',
      'address_text': 'Rua X, Porto',
      'status': status,
      'client_id': 'c1',
      'pro_id': 'p1',
      'trade_id': 3,
      'trades': {
        'id': 3,
        'display_name': 'Plumbing',
        'standard_rate': 35,
      },
      'created_at': '2026-04-10T09:00:00Z',
      'accepted_at': '2026-04-10T09:05:00Z',
      'started_at': status == 'in_progress' ? '2026-04-10T09:30:00Z' : null,
    },
    counterpartyRow: counterparty ??
        const {
          'id': 'p1',
          'full_name': 'Manuel Ferreira',
          'professional_profiles': {'verification_status': 'verified'},
        },
    viewerRole: role,
    photoUrls: photoUrls,
    reviewRow: reviewRow,
  );
}

Widget _wrap(JobDetailController controller) =>
    JobDetailScreen(
      jobId: 'j1',
      viewerRole: controller.viewerRole,
      controller: controller,
    );

void main() {
  group('JobDetailScreen — client', () {
    testWidgets('pending state shows cancel request button', (tester) async {
      final controller = JobDetailController(
        jobId: 'j1',
        viewerRole: ViewerRole.client,
        repo: _FakeRepo(
          detail: _detail(status: 'pending', role: ViewerRole.client),
        ),
      );

      await pumpTestApp(tester, _wrap(controller));
      await tester.pumpAndSettle();

      expect(find.text('Cancel request'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Leaking pipe'), findsWidgets);
    });

    testWidgets('accepted state shows counterparty and message+cancel',
        (tester) async {
      final controller = JobDetailController(
        jobId: 'j1',
        viewerRole: ViewerRole.client,
        repo: _FakeRepo(
          detail: _detail(status: 'accepted', role: ViewerRole.client),
        ),
      );

      await pumpTestApp(tester, _wrap(controller));
      await tester.pumpAndSettle();

      expect(find.text('Manuel Ferreira'), findsOneWidget);
      expect(find.text('Plumbing · Verified'), findsOneWidget);
      expect(find.text('Message'), findsOneWidget);
      expect(find.text('Cancel job'), findsOneWidget);
    });

    testWidgets('completed state shows submit review button', (tester) async {
      final controller = JobDetailController(
        jobId: 'j1',
        viewerRole: ViewerRole.client,
        repo: _FakeRepo(
          detail: _detail(status: 'completed', role: ViewerRole.client),
        ),
      );

      await pumpTestApp(tester, _wrap(controller));
      await tester.pumpAndSettle();

      expect(find.text('Submit review'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('completed state with existing review hides action and shows stars',
        (tester) async {
      final controller = JobDetailController(
        jobId: 'j1',
        viewerRole: ViewerRole.client,
        repo: _FakeRepo(
          detail: _detail(
            status: 'completed',
            role: ViewerRole.client,
            reviewRow: const {
              'id': 'r1',
              'request_id': 'j1',
              'client_id': 'c1',
              'pro_id': 'p1',
              'rating': 4,
              'comment': 'Quick and tidy',
              'created_at': '2026-04-11T09:00:00Z',
            },
          ),
        ),
      );

      await pumpTestApp(tester, _wrap(controller));
      await tester.pumpAndSettle();

      expect(find.text('Review submitted'), findsOneWidget);
      expect(find.text('Submit review'), findsNothing);
      expect(
        find.text('Quick and tidy', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('Your review of Manuel Ferreira', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('tapping Submit review opens the review sheet',
        (tester) async {
      final controller = JobDetailController(
        jobId: 'j1',
        viewerRole: ViewerRole.client,
        repo: _FakeRepo(
          detail: _detail(status: 'completed', role: ViewerRole.client),
        ),
      );

      await pumpTestApp(tester, _wrap(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit review'));
      await tester.pumpAndSettle();

      expect(find.text('Rate Manuel Ferreira'), findsOneWidget);
      expect(
        find.byKey(const Key('reviewSheet.submitButton')),
        findsOneWidget,
      );
    });

    testWidgets('cancelled state shows new-request button', (tester) async {
      final controller = JobDetailController(
        jobId: 'j1',
        viewerRole: ViewerRole.client,
        repo: _FakeRepo(
          detail: _detail(status: 'cancelled', role: ViewerRole.client),
        ),
      );

      await pumpTestApp(tester, _wrap(controller));
      await tester.pumpAndSettle();

      expect(find.text('Submit a new request'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
    });
  });

  group('JobDetailScreen — pro', () {
    testWidgets('accepted state shows start-heading-over button', (tester) async {
      final controller = JobDetailController(
        jobId: 'j1',
        viewerRole: ViewerRole.pro,
        repo: _FakeRepo(
          detail: _detail(
            status: 'accepted',
            role: ViewerRole.pro,
            counterparty: const {
              'id': 'c1',
              'full_name': 'João Silva',
              'phone': '+351 912',
            },
          ),
        ),
      );

      await pumpTestApp(tester, _wrap(controller));
      await tester.pumpAndSettle();

      expect(find.text('Start heading over'), findsOneWidget);
      expect(find.text('João Silva'), findsOneWidget);
    });

    testWidgets('in_progress state shows live timer and complete button',
        (tester) async {
      final controller = JobDetailController(
        jobId: 'j1',
        viewerRole: ViewerRole.pro,
        repo: _FakeRepo(
          detail: _detail(status: 'in_progress', role: ViewerRole.pro),
        ),
      );

      await pumpTestApp(tester, _wrap(controller));
      await tester.pumpAndSettle();

      expect(find.text('In progress'), findsWidgets); // pill + timer label
      expect(find.text('Mark job complete'), findsOneWidget);
    });
  });
}
