import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/client/request/controllers/request_controller.dart';
import 'package:project/features/client/request/data/models/trade_model.dart';
import 'package:project/features/client/request/data/repositories/request_repository.dart';
import 'package:project/features/shared/payments/data/models/payment_models.dart';
import 'package:project/features/shared/payments/data/repositories/payment_repository.dart';

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

class _FakePaymentRepository extends PaymentRepository {
  _FakePaymentRepository({this.defaultCard = 'card-1', this.onAuthorise});

  final String? defaultCard;
  final Future<void> Function(String requestId, String paymentMethodId)?
      onAuthorise;

  String? authorisedRequestId;
  String? authorisedPaymentMethodId;

  @override
  Future<String?> defaultCardId() async => defaultCard;

  @override
  Future<void> authorise({
    required String requestId,
    required String paymentMethodId,
  }) async {
    authorisedRequestId = requestId;
    authorisedPaymentMethodId = paymentMethodId;
    await onAuthorise?.call(requestId, paymentMethodId);
  }
}

void main() {
  group('RequestController', () {
    test('submits the payload then authorises the card', () async {
      Map<String, dynamic>? submittedData;
      final payments = _FakePaymentRepository();
      final controller = RequestController(
        repo: _FakeRequestRepository(
          onSubmitRequest: (data) async {
            submittedData = data;
          },
        ),
        paymentRepository: payments,
        currentUserIdProvider: () => 'client-123',
        requestIdGenerator: () => 'req-fixed-uuid',
      );

      final scheduledAt = DateTime.utc(2026, 4, 22, 14, 30);

      await controller.submit(
        tradeId: 4,
        title: 'Broken AC',
        description: 'The unit stopped cooling.',
        addressText: 'Rua das Flores 10',
        latitude: 41.1579,
        longitude: -8.6291,
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
      // Hold placed against the freshly-created request + default card.
      expect(payments.authorisedRequestId, 'req-fixed-uuid');
      expect(payments.authorisedPaymentMethodId, 'card-1');
    });

    test('blocks submission when the client has no saved card', () async {
      var submitCalled = false;
      final payments = _FakePaymentRepository(defaultCard: null);
      final controller = RequestController(
        repo: _FakeRequestRepository(
          onSubmitRequest: (_) async => submitCalled = true,
        ),
        paymentRepository: payments,
        currentUserIdProvider: () => 'client-123',
        requestIdGenerator: () => 'req-fixed-uuid',
      );

      await controller.submit(
        tradeId: 1,
        title: 'Leak',
        description: 'Pipe leaking',
        addressText: 'Rua do Heroismo 42',
        latitude: 41.1579,
        longitude: -8.6291,
        scheduledAt: null,
      );

      expect(submitCalled, isFalse);
      expect(controller.isSubmitted, isFalse);
      expect(controller.error, 'Add a payment card before submitting your request.');
      expect(payments.authorisedRequestId, isNull);
    });

    test('surfaces an authorisation failure after the request is created',
        () async {
      final payments = _FakePaymentRepository(
        onAuthorise: (_, _) async =>
            throw const PaymentException('card declined'),
      );
      final controller = RequestController(
        repo: _FakeRequestRepository(onSubmitRequest: (_) async {}),
        paymentRepository: payments,
        currentUserIdProvider: () => 'client-123',
        requestIdGenerator: () => 'req-fixed-uuid',
      );

      await controller.submit(
        tradeId: 1,
        title: 'Leak',
        description: 'Pipe leaking',
        addressText: 'Rua do Heroismo 42',
        latitude: 41.1579,
        longitude: -8.6291,
        scheduledAt: null,
      );

      expect(controller.isSubmitted, isFalse);
      expect(controller.error, contains('card declined'));
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
          paymentRepository: _FakePaymentRepository(),
          currentUserIdProvider: () => null,
        );

        await controller.submit(
          tradeId: 1,
          title: 'Leak',
          description: 'Pipe leaking',
          addressText: 'Rua do Heroismo 42',
          latitude: 41.1579,
          longitude: -8.6291,
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
        paymentRepository: _FakePaymentRepository(),
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
        paymentRepository: _FakePaymentRepository(),
        currentUserIdProvider: () => 'client-123',
      );

      await controller.submit(
        tradeId: 2,
        title: 'No power',
        description: 'Kitchen sockets stopped working',
        addressText: 'Avenida da Boavista 100',
        latitude: 41.1579,
        longitude: -8.6291,
        scheduledAt: null,
      );

      expect(controller.isSubmitted, isFalse);
      expect(controller.error, 'Could not create request');
    });
  });
}
