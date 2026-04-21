import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/incoming_jobs/data/models/incoming_job.dart';
import 'package:project/features/pro/incoming_jobs/presentation/widgets/incoming_job_card.dart';

import '../../../../../test_helpers.dart';

void main() {
  testWidgets('renders fallbacks, rejected state and action callbacks', (
    tester,
  ) async {
    var accepted = false;
    var rejected = false;

    await pumpTestApp(
      tester,
      IncomingJobCard(
        job: const IncomingJob(
          id: 'job-1',
          title: '',
          description: '',
          addressText: '',
          status: 'pending',
          createdAt: null,
          clientId: 'client-1',
          isRejected: true,
        ),
        onAccept: () => accepted = true,
        onReject: () => rejected = true,
      ),
    );

    expect(find.text('Untitled request'), findsOneWidget);
    expect(find.text('No description provided.'), findsOneWidget);
    expect(find.text('REJECTED'), findsOneWidget);
    expect(find.text('Reject again'), findsOneWidget);

    await tester.tap(find.text('Accept'));
    await tester.tap(find.text('Reject again'));

    expect(accepted, isTrue);
    expect(rejected, isTrue);
  });
}
