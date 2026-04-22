import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/client/request/controllers/request_controller.dart';
import 'package:project/features/client/request/data/models/trade_model.dart';
import 'package:project/features/client/request/data/repositories/request_repository.dart';

class _FakeRequestRepository extends RequestRepository {
  _FakeRequestRepository({this.onSubmitRequest, this.trades = const []});

  final Future<void> Function(Map<String, dynamic> data)? onSubmitRequest;
  final List<Trade> trades;

  @override
  Future<void> submitRequest(Map<String, dynamic> data) async {
    await onSubmitRequest?.call(data);
  }

  @override
  Future<List<Trade>> getTrades() async => trades;
}

void main() {
  group('RequestController', () {
    test('submits the expected payload for scheduled jobs', () async {
      Map<String, dynamic>? submittedData;
      final controller = RequestController(
        repo: _FakeRequestRepository(
          onSubmitRequest: (data) async {
            submittedData = data;
          },
        ),
        currentUserIdProvider: () => 'client-123',
        requestIdGenerator: () => 'req-fixed-uuid',
      );

      final scheduledAt = DateTime.utc(2026, 4, 22, 14, 30);

      await controller.submit(
        tradeId: 4,
        title: 'Broken AC',
        description: 'The unit stopped cooling.',
        addressText: 'Rua das Flores 10',
        scheduledAt: scheduledAt,
      );

      expect(controller.isSubmitted, isTrue);
      expect(controller.error, isNull);
      expect(submittedData, {
        'id': 'req-fixed-uuid',
        'client_id': 'client-123',
        'trade_id': 4,
        'title': 'Broken AC',
        'description': 'The unit stopped cooling.',
        'address_text': 'Rua das Flores 10',
        'location': 'POINT(-8.6291 41.1579)',
        'scheduled_at': '2026-04-22T14:30:00.000Z',
        'photo_urls': <Object>[],
      });
    });

    test(
      'reports missing authenticated users without calling the repository',
      () async {
        var called = false;
        final controller = RequestController(
          repo: _FakeRequestRepository(
            onSubmitRequest: (data) async {
              called = true;
            },
          ),
          currentUserIdProvider: () => null,
        );

        await controller.submit(
          tradeId: 1,
          title: 'Leak',
          description: 'Pipe leaking',
          addressText: 'Rua do Heroismo 42',
          scheduledAt: null,
        );

        expect(called, isFalse);
        expect(controller.isSubmitted, isFalse);
        expect(controller.error, 'No authenticated user.');
      },
    );

    test('loadTrades populates the trades list', () async {
      const seed = [
        Trade(id: 1, slug: 'plumbing', displayName: 'Plumbing', standardRate: 35),
        Trade(id: 2, slug: 'electrical', displayName: 'Electrical', standardRate: 40),
      ];
      final controller = RequestController(
        repo: _FakeRequestRepository(trades: seed),
        currentUserIdProvider: () => 'client-123',
      );

      await controller.loadTrades();

      expect(controller.trades, seed);
      expect(controller.isLoadingTrades, isFalse);
      expect(controller.tradesError, isNull);
    });

    test('exposes repository failures to the UI', () async {
      final controller = RequestController(
        repo: _FakeRequestRepository(
          onSubmitRequest: (data) async {
            throw const RequestFailure('Could not create request');
          },
        ),
        currentUserIdProvider: () => 'client-123',
      );

      await controller.submit(
        tradeId: 2,
        title: 'No power',
        description: 'Kitchen sockets stopped working',
        addressText: 'Avenida da Boavista 100',
        scheduledAt: null,
      );

      expect(controller.isSubmitted, isFalse);
      expect(controller.error, 'Could not create request');
    });
  });
}
