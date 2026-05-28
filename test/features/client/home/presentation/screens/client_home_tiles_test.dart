import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/client/home/presentation/screens/client_home_screen.dart';
import 'package:project/features/client/request/data/models/trade_model.dart';
import 'package:project/features/client/request/data/repositories/request_repository.dart';

import '../../../../../test_helpers.dart';

class _FakeTradesRepository extends RequestRepository {
  @override
  Future<List<Trade>> getTrades() async => const [
        Trade(id: 1, slug: 'plumbing', displayName: 'Plumbing', standardRate: 35),
        Trade(
            id: 2, slug: 'electrical', displayName: 'Electrical', standardRate: 40),
      ];
}

void main() {
  group('ClientHomeScreen trade tiles', () {
    testWidgets('renders a tile per trade and opens the request flow on tap', (
      tester,
    ) async {
      var openedRequestFlow = false;

      await pumpTestApp(
        tester,
        ClientHomeScreen(
          tradesRepository: _FakeTradesRepository(),
          requestScreenBuilder: (_) {
            openedRequestFlow = true;
            return const Scaffold(body: Text('request flow'));
          },
        ),
      );
      await tester.pumpAndSettle();

      // A tile per DB trade, labelled with the trade name.
      expect(find.byKey(const Key('homeTradeTile_1')), findsOneWidget);
      expect(find.byKey(const Key('homeTradeTile_2')), findsOneWidget);
      expect(find.text('Plumbing'), findsOneWidget);
      expect(find.text('Electrical'), findsOneWidget);

      // Tapping a tile launches the request flow.
      await tester.tap(find.byKey(const Key('homeTradeTile_2')));
      await tester.pumpAndSettle();
      expect(openedRequestFlow, isTrue);
      expect(find.text('request flow'), findsOneWidget);
    });

    testWidgets('the generic Request a job button opens the request flow', (
      tester,
    ) async {
      var openedRequestFlow = false;

      await pumpTestApp(
        tester,
        ClientHomeScreen(
          tradesRepository: _FakeTradesRepository(),
          requestScreenBuilder: (_) {
            openedRequestFlow = true;
            return const Scaffold(body: Text('request flow'));
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('goToRequestButton')));
      await tester.tap(find.byKey(const Key('goToRequestButton')));
      await tester.pumpAndSettle();
      expect(openedRequestFlow, isTrue);
    });
  });
}
