import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/shared/payments/controllers/payment_methods_controller.dart';
import 'package:project/features/shared/payments/data/models/payment_models.dart';
import 'package:project/features/shared/payments/data/repositories/payment_repository.dart';

class _FakePaymentRepository extends PaymentRepository {
  _FakePaymentRepository({
    this.onFetchCards,
    this.onAddCard,
    this.onSetDefault,
  });

  final Future<List<SavedCard>> Function()? onFetchCards;
  final Future<bool> Function()? onAddCard;
  final Future<void> Function(String cardId)? onSetDefault;

  int fetchCardsCalls = 0;
  int addCardCalls = 0;
  String? lastDefaultSet;

  @override
  Future<List<SavedCard>> fetchCards() async {
    fetchCardsCalls++;
    return onFetchCards?.call() ?? const [];
  }

  @override
  Future<bool> addCard() async {
    addCardCalls++;
    return onAddCard?.call() ?? false;
  }

  @override
  Future<void> setDefaultCard(String cardId) async {
    lastDefaultSet = cardId;
    await onSetDefault?.call(cardId);
  }
}

SavedCard _card(String id, {bool isDefault = false}) => SavedCard(
      id: id,
      stripePaymentMethodId: 'pm_$id',
      brand: 'visa',
      last4: '4242',
      isDefault: isDefault,
    );

void main() {
  group('PaymentMethodsController.load', () {
    test('populates cards on success', () async {
      final controller = PaymentMethodsController(
        repo: _FakePaymentRepository(
          onFetchCards: () async => [_card('a', isDefault: true), _card('b')],
        ),
      );

      await controller.load();

      expect(controller.cards.length, 2);
      expect(controller.isLoading, isFalse);
      expect(controller.error, isNull);
    });

    test('surfaces PaymentException message', () async {
      final controller = PaymentMethodsController(
        repo: _FakePaymentRepository(
          onFetchCards: () async => throw const PaymentException('rls blocked'),
        ),
      );

      await controller.load();

      expect(controller.error, 'rls blocked');
      expect(controller.cards, isEmpty);
    });
  });

  group('PaymentMethodsController.addCard', () {
    test('reloads and shows the new card on success', () async {
      var cards = <SavedCard>[];
      final repo = _FakePaymentRepository(
        onFetchCards: () async => cards,
        onAddCard: () async {
          cards = [_card('a', isDefault: true)]; // webhook wrote the row
          return true;
        },
      );
      final controller = PaymentMethodsController(repo: repo);

      final added = await controller.addCard();

      expect(added, isTrue);
      expect(controller.cards.length, 1);
      expect(controller.isAddingCard, isFalse);
      expect(controller.error, isNull);
    });

    test('returns false and does not error when user cancels', () async {
      final controller = PaymentMethodsController(
        repo: _FakePaymentRepository(onAddCard: () async => false),
      );

      final added = await controller.addCard();

      expect(added, isFalse);
      expect(controller.error, isNull);
    });

    test('captures PaymentException as error', () async {
      final controller = PaymentMethodsController(
        repo: _FakePaymentRepository(
          onAddCard: () async => throw const PaymentException('sheet failed'),
        ),
      );

      final added = await controller.addCard();

      expect(added, isFalse);
      expect(controller.error, 'sheet failed');
    });
  });

  group('PaymentMethodsController.setDefault', () {
    test('delegates to the repo and refreshes', () async {
      var cards = [_card('a', isDefault: true), _card('b')];
      final repo = _FakePaymentRepository(
        onFetchCards: () async => cards,
        onSetDefault: (id) async {
          cards = [_card('a'), _card('b', isDefault: true)];
        },
      );
      final controller = PaymentMethodsController(repo: repo);

      await controller.setDefault('b');

      expect(repo.lastDefaultSet, 'b');
      expect(controller.cards.firstWhere((c) => c.id == 'b').isDefault, isTrue);
      expect(controller.error, isNull);
    });

    test('surfaces failure message', () async {
      final controller = PaymentMethodsController(
        repo: _FakePaymentRepository(
          onSetDefault: (_) async => throw const PaymentException('no update policy'),
        ),
      );

      await controller.setDefault('b');

      expect(controller.error, 'no update policy');
    });
  });
}
