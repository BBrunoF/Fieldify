import 'package:project/features/shared/payments/data/models/payment_models.dart';
import 'package:project/features/shared/payments/data/repositories/payment_repository.dart';
// PaymentException is re-exported from payment_models.dart above; no extra
// import needed.

/// A Stripe-free [PaymentRepository] for integration tests.
///
/// The real flow requires a saved card and a live Stripe authorisation before a
/// request can be submitted (and a capture when a job completes). Patrol can't
/// drive Stripe's native PaymentSheet, so this fake pretends the client always
/// has a default card on file and makes every Stripe round-trip a no-op. That
/// lets the request-submit and job-detail flows complete end-to-end against the
/// real Supabase backend without ever touching Stripe.
class FakePaymentRepository extends PaymentRepository {
  static const _card = SavedCard(
    id: 'test-card',
    stripePaymentMethodId: 'pm_test',
    brand: 'visa',
    last4: '4242',
    isDefault: true,
  );

  @override
  Future<List<SavedCard>> fetchCards() async => const [_card];

  @override
  Future<String?> defaultCardId() async => _card.id;

  @override
  Future<void> authorise({
    required String requestId,
    required String paymentMethodId,
  }) async {}

  @override
  Future<void> capture({
    required String requestId,
    required double amountEuros,
  }) async {
    // The real capture Edge Function both charges Stripe AND flips the
    // service_request row to "completed". Since we can't drive Stripe in
    // tests, throw a "no payment" PaymentException — JobDetailController
    // treats that as "fall back to plain markCompleted on the repo", which
    // performs the same status flip via Supabase directly.
    throw const PaymentException('no payment to capture in tests');
  }

  @override
  Future<PaymentInfo?> fetchPaymentForRequest(String requestId) async => null;
}

/// Installs [FakePaymentRepository] as the app-wide payments implementation.
/// Idempotent — safe to call from `patrolSetUp` before every test.
void installFakePayments() {
  PaymentRepository.debugOverride = () => FakePaymentRepository();
}
