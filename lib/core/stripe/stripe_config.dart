import 'package:flutter_stripe/flutter_stripe.dart';

/// Stripe **publishable** key (safe to ship in the client — it is NOT the
/// secret key). Grab it from Stripe Dashboard → Developers → API keys.
///
/// Override at build time with:
///   flutter run --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx
/// otherwise the default below is used.
const stripePublishableKey = String.fromEnvironment(
  'STRIPE_PUBLISHABLE_KEY',
  defaultValue: 'pk_test_51TWNzkFRsAkvsvcuOnMj7wQOcba5tOBiAZYdX3cskyfouu4UfVffOpC60RJ7wyaIDC3IoSpbcCnMIyhOYsWVaTQP00904FF8e3',
);

/// Initialises the Stripe SDK. Call once during app startup, before any
/// PaymentSheet is presented.
Future<void> initializeStripe() async {
  Stripe.publishableKey = stripePublishableKey;
  // Required for Apple Pay / some flows; harmless otherwise.
  Stripe.merchantIdentifier = 'merchant.app.fieldify';
  await Stripe.instance.applySettings();
}
