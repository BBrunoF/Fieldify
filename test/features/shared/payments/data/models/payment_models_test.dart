import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/shared/payments/data/models/payment_models.dart';

void main() {
  group('SavedCard.fromJson', () {
    test('parses all fields', () {
      final card = SavedCard.fromJson({
        'id': 'pm-row-1',
        'stripe_payment_method_id': 'pm_123',
        'card_brand': 'visa',
        'card_last4': '4242',
        'is_default': true,
      });

      expect(card.id, 'pm-row-1');
      expect(card.stripePaymentMethodId, 'pm_123');
      expect(card.brand, 'visa');
      expect(card.last4, '4242');
      expect(card.isDefault, isTrue);
    });

    test('defaults missing/null fields safely', () {
      final card = SavedCard.fromJson({'id': 'pm-row-2'});

      expect(card.stripePaymentMethodId, '');
      expect(card.brand, '');
      expect(card.last4, '');
      expect(card.isDefault, isFalse);
    });

    test('brandLabel capitalises the brand, falls back to "Card"', () {
      expect(
        SavedCard.fromJson({'id': 'x', 'card_brand': 'mastercard'}).brandLabel,
        'Mastercard',
      );
      expect(SavedCard.fromJson({'id': 'x'}).brandLabel, 'Card');
    });

    test('masked renders the last 4 digits', () {
      final card = SavedCard.fromJson({'id': 'x', 'card_last4': '4242'});
      expect(card.masked, '•••• •••• •••• 4242');
    });
  });

  group('PaymentInfo.fromJson', () {
    test('parses an authorised payment', () {
      final p = PaymentInfo.fromJson({
        'status': 'authorised',
        'amount_authorised': 280,
        'amount_charged': null,
        'platform_fee': null,
      });

      expect(p.status, 'authorised');
      expect(p.amountAuthorised, 280);
      expect(p.amountCharged, isNull);
      expect(p.platformFee, isNull);
      expect(p.isAuthorised, isTrue);
      expect(p.isCaptured, isFalse);
    });

    test('parses a captured payment', () {
      final p = PaymentInfo.fromJson({
        'status': 'captured',
        'amount_authorised': 280,
        'amount_charged': 17.5,
        'platform_fee': 1.75,
      });

      expect(p.isCaptured, isTrue);
      expect(p.isAuthorised, isFalse);
      expect(p.amountCharged, 17.5);
      expect(p.platformFee, 1.75);
    });

    test('defaults amounts when missing', () {
      final p = PaymentInfo.fromJson({'status': 'cancelled'});
      expect(p.amountAuthorised, 0);
      expect(p.amountCharged, isNull);
    });
  });
}
