# Stripe Integration Design

**Date:** 2026-05-11
**Status:** Approved

## Summary

Integrate Stripe Connect into Fieldify as a two-sided marketplace: clients pay via Stripe, professionals receive automatic payouts. The platform takes a commission on every job. Payment is split into a deposit (at job confirmation) and a final settlement (at job completion).

---

## Decisions

| Decision | Choice | Reason |
|---|---|---|
| Stripe integration approach | `flutter_stripe` + Supabase Edge Functions | Native PaymentSheet UX, secret key stays server-side |
| Connect account type | Express | Stripe handles KYC/compliance, fastest to build for MVP |
| Payment timing | Deposit + final settlement | Hourly billing — final amount unknown until job completes |
| Commission model | `application_fee_amount` on every PaymentIntent | Stripe auto-splits; no manual transfers needed |
| Card collection point | Request screen Step 4 (SetupIntent) | Card saved before a pro accepts; deposit becomes one-tap confirm |

---

## Architecture

Flutter calls Supabase Edge Functions for all Stripe operations. Edge Functions hold the Stripe secret key. Flutter only ever receives a short-lived `client_secret` and passes it directly to the Stripe SDK.

```
Flutter (flutter_stripe)
    └── calls → Supabase Edge Functions (Deno/TS)
                    └── calls → Stripe API
                                    └── webhooks back → Edge Functions → Supabase DB
```

---

## Database Changes

No new tables. Add columns to existing tables only.

### Client profile table
| Column | Type | Notes |
|---|---|---|
| `stripe_customer_id` | `text` | Stripe Customer ID (`cus_xxx`), set on first SetupIntent |

### Pro profile table
| Column | Type | Notes |
|---|---|---|
| `stripe_account_id` | `text` | Stripe Express account ID (`acct_xxx`) |
| `stripe_onboarding_complete` | `bool` | Set to `true` by webhook when `charges_enabled: true` |

### Jobs table
| Column | Type | Notes |
|---|---|---|
| `deposit_amount` | `int` | Amount in cents |
| `total_amount` | `int` | Populated when job completes (rate × duration) |
| `deposit_payment_intent_id` | `text` | Used by webhook to match events |
| `settlement_payment_intent_id` | `text` | Used by webhook to match events |

---

## Edge Functions

### `POST /functions/v1/create-setup-intent`
Called by the request screen Step 4 when the client has no saved card.

- Creates a Stripe Customer if `stripe_customer_id` is null on the client profile
- Saves `stripe_customer_id` to the client profile row
- Creates a SetupIntent for that Customer
- Returns `{ client_secret }` → Flutter presents PaymentSheet to collect and save card

### `POST /functions/v1/create-connect-account`
Called by the pro profile screen "Connect Stripe" button.

- Creates a Stripe Express account
- Saves `stripe_account_id` to the pro profile row
- Generates an Account Link (onboarding URL)
- Returns `{ onboarding_url }` → Flutter opens it in a browser

### `POST /functions/v1/create-payment-intent`
Called by client payment screens. Used twice per job: once for deposit, once for settlement.

Body: `{ job_id, type: "deposit" | "settlement" }`

- Fetches job row to get rate, duration, deposit already paid, and pro's `stripe_account_id`
- Calculates the amount for this charge
- Creates a PaymentIntent with:
  - `transfer_data.destination` → pro's Express account
  - `application_fee_amount` → platform commission
  - `customer` → client's `stripe_customer_id`
  - `payment_method` → client's saved payment method (for one-tap confirm)
  - `currency: "eur"`
- Saves `payment_intent_id` to the job row
- Returns `{ client_secret, amount, currency }`

### `POST /functions/v1/stripe-webhook`
Called by Stripe directly (not Flutter). Registered in the Stripe dashboard.

Handles:
- `payment_intent.succeeded` → looks up job by `payment_intent_id`, updates job status to deposit-paid or settled
- `account.updated` → sets `stripe_onboarding_complete = true` on pro profile when `charges_enabled: true`

Always verifies the webhook signature before processing. Always responds `200` immediately.

---

## Flutter Layer

### New feature folder: `lib/features/client/payment/`

```
lib/features/client/payment/
├── controllers/
│   └── payment_controller.dart       # ChangeNotifier — _loading, _error, triggers PaymentSheet
├── data/
│   ├── repositories/
│   │   └── payment_repository.dart   # catches errors, rethrows as PaymentFailure
│   └── services/
│       └── payment_service.dart      # raw HTTP POST to Edge Functions
└── presentation/screens/
    ├── deposit_screen.dart            # shown after pro accepts job
    └── settlement_screen.dart         # shown when pro marks job complete
```

Follows the existing `Screen → Controller → Repository → Service → Supabase/Edge` pattern exactly.

### Pro onboarding (no new folder)
Stripe Connect onboarding piggybacks on the existing pro profile feature:
- `pro_profile_screen.dart` — add a Stripe status card: "Connect Stripe" button or "Payouts enabled ✓"
- `pro_profile_controller.dart` — add `connectStripe()` method that calls the repository

### Existing files with small changes

| File | Change |
|---|---|
| `request_screen.dart` `_buildPaymentCard()` | If no saved card → trigger SetupIntent + PaymentSheet. If card saved → show saved card with "Change" option. |
| `client_action_bar.dart` | Add `"Pay Deposit"` primary button for `JobStatus.accepted` (only when deposit not yet paid). |
| `pro_action_bar.dart` | Disable "Mark Complete" until deposit is confirmed paid. |
| `payment_summary_card.dart` | Replace "payments coming soon" with real deposit status, settlement status, and final total. |

---

## Payment Flows

### Client card setup (request screen, first time only)
1. Client reaches Step 4 of request screen — no saved card exists
2. `PaymentController.setupCard()` → Service POSTs to `create-setup-intent`
3. Edge Function creates Stripe Customer + SetupIntent, saves `stripe_customer_id`
4. Flutter presents `PaymentSheet` — client enters card details
5. Card is saved to Stripe Customer for future use

### Deposit (after pro accepts job)
1. Client opens job detail → sees "Pay Deposit" in action bar
2. `PaymentController.payDeposit(jobId)` → Service POSTs to `create-payment-intent` with `type: "deposit"`
3. Edge Function creates PaymentIntent with saved card + `transfer_data` + `application_fee_amount`
4. Flutter presents PaymentSheet — client one-tap confirms
5. Stripe webhook fires `payment_intent.succeeded` → job status updated to deposit-paid

### Final settlement (after pro marks job complete)
1. Pro marks job complete → client is notified
2. Client opens job detail → sees "Pay Balance" in action bar
3. `PaymentController.paySettlement(jobId)` → Service POSTs to `create-payment-intent` with `type: "settlement"`
4. Edge Function computes remainder (`total_amount - deposit_amount`), creates PaymentIntent
5. Flutter presents PaymentSheet — client one-tap confirms
6. Stripe webhook fires `payment_intent.succeeded` → job status updated to settled → Stripe auto-pays pro

### Pro Stripe onboarding (one-time)
1. Pro opens profile → sees "Connect Stripe" card
2. `ProProfileController.connectStripe()` → POSTs to `create-connect-account`
3. Edge Function creates Express account, saves `stripe_account_id`
4. Flutter opens returned `onboarding_url` in browser via `url_launcher`
5. Pro completes Stripe-hosted KYC
6. Stripe webhook fires `account.updated` → `stripe_onboarding_complete` set to `true`
7. Pro profile screen refreshes — shows "Payouts enabled ✓"

---

## Open Configuration Values

These are business decisions not yet set — they should be defined as constants before implementation:

| Value | Where | Notes |
|---|---|---|
| Deposit percentage | `app_constants.dart` | e.g. `depositPercent = 30` — % of estimated total charged upfront |
| Commission percentage | `Trade.platformFeePercent` | Already exists in codebase |

The deposit amount is calculated as: `estimated_hours × rate × depositPercent / 100`. Estimated hours must be added to the request form or defaulted (e.g. 1h) since the client doesn't know duration upfront.

---

## New Dependencies

| Package | Purpose |
|---|---|
| `flutter_stripe` | Native PaymentSheet, card collection |
| `url_launcher` | Open Stripe Express onboarding URL in browser |

Both added to `pubspec.yaml`.

---

## Security Notes

- Stripe secret key is set as a Supabase Edge Function environment variable — never in Flutter
- Flutter only receives `client_secret` tokens (scoped to one payment, short-lived)
- Webhook endpoint verifies Stripe signature on every request to prevent spoofing
- Pro cannot receive payouts until `stripe_onboarding_complete = true` — Edge Function checks this before creating a PaymentIntent
