/// Thrown for any payment-related failure surfaced to the UI.
class PaymentException implements Exception {
  final String message;
  const PaymentException(this.message);

  @override
  String toString() => message;
}

/// A card the client has saved (row from `payment_methods`).
class SavedCard {
  final String id;
  final String stripePaymentMethodId;
  final String brand;
  final String last4;
  final bool isDefault;

  const SavedCard({
    required this.id,
    required this.stripePaymentMethodId,
    required this.brand,
    required this.last4,
    required this.isDefault,
  });

  String get brandLabel =>
      brand.isEmpty ? 'Card' : brand[0].toUpperCase() + brand.substring(1);

  String get masked => '•••• •••• •••• $last4';

  factory SavedCard.fromJson(Map<String, dynamic> json) {
    return SavedCard(
      id: json['id'] as String,
      stripePaymentMethodId: (json['stripe_payment_method_id'] ?? '') as String,
      brand: (json['card_brand'] ?? '') as String,
      last4: (json['card_last4'] ?? '') as String,
      isDefault: (json['is_default'] as bool?) ?? false,
    );
  }
}

/// A row from `payments` for a given request.
class PaymentInfo {
  final String status; // authorised | captured | cancelled | refunded
  final double amountAuthorised;
  final double? amountCharged;
  final double? platformFee;

  const PaymentInfo({
    required this.status,
    required this.amountAuthorised,
    required this.amountCharged,
    required this.platformFee,
  });

  bool get isAuthorised => status == 'authorised';
  bool get isCaptured => status == 'captured';

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      status: (json['status'] ?? '') as String,
      amountAuthorised: (json['amount_authorised'] as num?)?.toDouble() ?? 0,
      amountCharged: (json['amount_charged'] as num?)?.toDouble(),
      platformFee: (json['platform_fee'] as num?)?.toDouble(),
    );
  }
}
