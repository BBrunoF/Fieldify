import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../../../core/supabase/supabase_client.dart';
import '../models/payment_models.dart';

/// Thin wrapper over the Stripe edge functions + the native Stripe SDK.
class PaymentService {
  String? getCurrentUserId() => supabase.auth.currentUser?.id;

  String _errorFrom(dynamic data, String fallback) {
    if (data is Map<String, dynamic> && data['error'] is String) {
      return data['error'] as String;
    }
    return fallback;
  }

  // ── Card management ────────────────────────────────────────────────

  Future<List<SavedCard>> fetchCards() async {
    final user = supabase.auth.currentUser;
    if (user == null) return const [];
    final rows = await supabase
        .from('payment_methods')
        .select('id, stripe_payment_method_id, card_brand, card_last4, is_default')
        .eq('profile_id', user.id)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => SavedCard.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Makes [cardId] the client's default card (clears the flag on the others).
  Future<void> setDefaultCard(String cardId) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw const PaymentException('Not authenticated');

    await supabase
        .from('payment_methods')
        .update({'is_default': false})
        .eq('profile_id', user.id);

    final updated = await supabase
        .from('payment_methods')
        .update({'is_default': true})
        .eq('id', cardId)
        .eq('profile_id', user.id)
        .select('id');

    if ((updated as List).isEmpty) {
      throw const PaymentException(
        'Could not update default card — check RLS policies on payment_methods.',
      );
    }
  }

  /// Returns the id of the client's default saved card, or null if none.
  Future<String?> defaultCardId() async {
    final cards = await fetchCards();
    if (cards.isEmpty) return null;
    final def = cards.where((c) => c.isDefault);
    return (def.isNotEmpty ? def.first : cards.first).id;
  }

  /// Presents Stripe's PaymentSheet in SetupIntent mode so the client can save
  /// a card. The `setup_intent.succeeded` webhook persists the card to
  /// `payment_methods`. Throws [PaymentException] on failure; silently returns
  /// if the user cancels the sheet.
  Future<bool> addCard() async {
    final res = await supabase.functions.invoke('create-setup-intent');
    if (res.status != 200) {
      throw PaymentException(_errorFrom(res.data, 'Could not start card setup'));
    }
    final clientSecret =
        (res.data as Map<String, dynamic>)['client_secret'] as String?;
    if (clientSecret == null || clientSecret.isEmpty) {
      throw const PaymentException('Stripe did not return a client secret');
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        merchantDisplayName: 'Fieldify',
        setupIntentClientSecret: clientSecret,
      ),
    );

    try {
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      // User tapped cancel/back — not an error worth surfacing.
      if (e.error.code == FailureCode.Canceled) return false;
      throw PaymentException(e.error.localizedMessage ?? 'Card setup failed');
    }
  }

  // ── Authorise / capture ────────────────────────────────────────────

  Future<PaymentInfo?> fetchPaymentForRequest(String requestId) async {
    try {
      final row = await supabase
          .from('payments')
          .select('status, amount_authorised, amount_charged, platform_fee')
          .eq('request_id', requestId)
          .maybeSingle();
      if (row == null) return null;
      return PaymentInfo.fromJson(row);
    } catch (_) {
      // RLS / network — treat as "no payment visible" rather than crashing.
      return null;
    }
  }

  /// Authorises (holds) funds on the client's card for [requestId].
  Future<void> authorise({
    required String requestId,
    required String paymentMethodId,
  }) async {
    final res = await supabase.functions.invoke(
      'create-payment-intent',
      body: {'request_id': requestId, 'payment_method_id': paymentMethodId},
    );
    if (res.status != 200) {
      throw PaymentException(
        _errorFrom(res.data, 'Could not authorise payment'),
      );
    }
  }

  /// Captures [amountEuros] from the previously-authorised payment. The edge
  /// function also flips the request to `completed`.
  Future<void> capture({
    required String requestId,
    required double amountEuros,
  }) async {
    final res = await supabase.functions.invoke(
      'capture-payment-intent',
      body: {'request_id': requestId, 'amount_to_capture': amountEuros},
    );
    if (res.status != 200) {
      throw PaymentException(_errorFrom(res.data, 'Could not capture payment'));
    }
  }
}
