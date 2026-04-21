import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/client/request/controllers/request_controller.dart';
import 'package:project/features/client/request/data/models/trade_model.dart';
import 'package:project/features/client/request/data/repositories/request_repository.dart';
import 'package:project/features/client/request/presentation/screens/request_screen.dart';

import '../../../../../test_helpers.dart';

const _seedTrades = [
  Trade(id: 1, slug: 'plumbing', displayName: 'Plumbing', standardRate: 35),
  Trade(id: 2, slug: 'electrical', displayName: 'Electrical', standardRate: 40),
  Trade(id: 3, slug: 'carpentry', displayName: 'Carpentry', standardRate: 35),
  Trade(id: 4, slug: 'hvac', displayName: 'HVAC', standardRate: 45),
  Trade(id: 5, slug: 'painting', displayName: 'Painting', standardRate: 30),
  Trade(id: 6, slug: 'other', displayName: 'Other', standardRate: 35),
];

class _FakeRequestRepository extends RequestRepository {
  _FakeRequestRepository({this.onSubmitRequest});

  final Future<void> Function(Map<String, dynamic> data)? onSubmitRequest;
  final List<Trade> trades = _seedTrades;

  @override
  Future<void> submitRequest(Map<String, dynamic> data) async {
    await onSubmitRequest?.call(data);
  }

  @override
  Future<List<Trade>> getTrades() async => trades;
}

void main() {
  group('RequestScreen', () {
    testWidgets('shows schedule controls only when schedule is selected', (
      tester,
    ) async {
      final controller = RequestController(
        repo: _FakeRequestRepository(),
        currentUserIdProvider: () => 'client-123',
      );

      await pumpTestApp(tester, RequestScreen(controller: controller));

      await tester.tap(find.byKey(const Key('requestPrimaryButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('requestPrimaryButton')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('requestScheduleOption')),
      );
      await tester.tap(find.byKey(const Key('requestScheduleOption')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('requestDateButton')));
      expect(find.byKey(const Key('requestDateButton')), findsOneWidget);
      expect(find.byKey(const Key('requestTimeButton')), findsOneWidget);
    });

    testWidgets('submits the flow and shows the success screen', (
      tester,
    ) async {
      Map<String, dynamic>? submittedData;
      final controller = RequestController(
        repo: _FakeRequestRepository(
          onSubmitRequest: (data) async {
            submittedData = data;
          },
        ),
        currentUserIdProvider: () => 'client-123',
      );

      await pumpTestApp(tester, RequestScreen(controller: controller));

      await tester.tap(find.byKey(const Key('requestCategoryCard_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('requestPrimaryButton')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('requestTitleField')),
        'Lights are flickering',
      );
      await tester.enterText(
        find.byKey(const Key('requestDescriptionField')),
        'The living room lights flicker every few minutes.',
      );
      await tester.tap(find.byKey(const Key('requestPrimaryButton')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('requestAddressField')),
        'Rua de Cedofeita 25',
      );
      await tester.tap(find.byKey(const Key('requestPrimaryButton')));
      await tester.pumpAndSettle();

      expect(find.text('Review & submit'), findsOneWidget);
      expect(find.text('Electrical'), findsOneWidget);
      expect(find.text('Lights are flickering'), findsOneWidget);

      await tester.tap(find.byKey(const Key('requestPrimaryButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('requestSubmittedScreen')), findsOneWidget);
      expect(find.byKey(const Key('requestSubmittedTitle')), findsOneWidget);
      expect(submittedData?['trade_id'], 2);
      expect(submittedData?['title'], 'Lights are flickering');
      expect(submittedData?['scheduled_at'], isNull);
    });
  });
}
