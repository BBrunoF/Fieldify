import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_models.dart';
import '../services/payment_service.dart';

class PaymentRepository {
  final PaymentService _service;

  PaymentRepository({PaymentService? service})
      : _service = service ?? PaymentService();

  /// Test seam. When set (only by patrol integration tests), [resolve] returns
  /// this builder's result instead of a Stripe-backed repository, letting the
  /// request-submit and job-detail flows complete without a real card or a
  /// Stripe round-trip. Never assigned in production code.
  static PaymentRepository Function()? debugOverride;

  /// The payments repository the app should use: the installed [debugOverride]
  /// when present, otherwise a real Stripe-backed [PaymentRepository].
  static PaymentRepository resolve() =>
      debugOverride?.call() ?? PaymentRepository();

  String? getCurrentUserId() => _service.getCurrentUserId();

  Future<List<SavedCard>> fetchCards() async {
    try {
      return await _service.fetchCards();
    } on PostgrestException catch (e) {
      throw PaymentException(e.message);
    }
  }

  Future<String?> defaultCardId() async {
    try {
      return await _service.defaultCardId();
    } on PostgrestException catch (e) {
      throw PaymentException(e.message);
    }
  }

  /// Returns true if a card was added, false if the user cancelled.
  Future<bool> addCard() => _service.addCard();

  Future<void> setDefaultCard(String cardId) async {
    try {
      await _service.setDefaultCard(cardId);
    } on PostgrestException catch (e) {
      throw PaymentException(e.message);
    }
  }

  Future<PaymentInfo?> fetchPaymentForRequest(String requestId) =>
      _service.fetchPaymentForRequest(requestId);

  Future<void> authorise({
    required String requestId,
    required String paymentMethodId,
  }) =>
      _service.authorise(requestId: requestId, paymentMethodId: paymentMethodId);

  Future<void> capture({
    required String requestId,
    required double amountEuros,
  }) =>
      _service.capture(requestId: requestId, amountEuros: amountEuros);
}
