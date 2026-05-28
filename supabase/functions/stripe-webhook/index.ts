import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { stripe } from "../_shared/stripe.ts";
import { adminClient } from "../_shared/supabase.ts";

// Two endpoints in Stripe — one for platform events (payment_intent.*,
// setup_intent.*), one for Connect events (account.updated). Each has its
// own signing secret. Try each in turn until one verifies.
const webhookSecrets = [
  Deno.env.get("STRIPE_WEBHOOK_SECRET"),
  Deno.env.get("STRIPE_WEBHOOK_SECRET_CONNECT"),
].filter((s): s is string => Boolean(s));

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  if (webhookSecrets.length === 0) {
    console.error("No webhook secrets configured (STRIPE_WEBHOOK_SECRET / STRIPE_WEBHOOK_SECRET_CONNECT)");
    return new Response("Webhook not configured", { status: 500 });
  }

  const signature = req.headers.get("stripe-signature");
  if (!signature) return new Response("Missing stripe-signature header", { status: 400 });

  const rawBody = await req.text();

  let event;
  let lastError = "no secrets matched";
  for (const secret of webhookSecrets) {
    try {
      event = await stripe.webhooks.constructEventAsync(rawBody, signature, secret);
      break;
    } catch (err) {
      lastError = err instanceof Error ? err.message : "unknown";
    }
  }

  if (!event) {
    console.error("Signature verification failed against all secrets:", lastError);
    return new Response(`Signature verification failed: ${lastError}`, { status: 400 });
  }

  const supabase = adminClient();
  const now = new Date().toISOString();

  try {
    switch (event.type) {
      case "setup_intent.succeeded": {
        const si = event.data.object as {
          payment_method?: string;
          customer?: string;
        };
        if (!si.payment_method || !si.customer) break;

        const pm = await stripe.paymentMethods.retrieve(si.payment_method);
        if (pm.type !== "card" || !pm.card) break;

        const { data: profile } = await supabase
          .from("profiles")
          .select("id")
          .eq("stripe_customer_id", si.customer)
          .single();
        if (!profile) break;

        const { count } = await supabase
          .from("payment_methods")
          .select("id", { count: "exact", head: true })
          .eq("profile_id", profile.id);
        const isFirstCard = (count ?? 0) === 0;

        await supabase.from("payment_methods").upsert(
          {
            profile_id: profile.id,
            stripe_payment_method_id: pm.id,
            card_brand: pm.card.brand,
            card_last4: pm.card.last4,
            is_default: isFirstCard,
          },
          { onConflict: "stripe_payment_method_id" },
        );
        break;
      }

      case "payment_intent.succeeded": {
        // Idempotent — capture-payment-intent already flipped state.
        // We only update if still 'authorised' (defends against out-of-order events).
        const pi = event.data.object as { id: string };
        await supabase
          .from("payments")
          .update({ status: "captured", updated_at: now })
          .eq("stripe_payment_intent_id", pi.id)
          .eq("status", "authorised");
        break;
      }

      case "payment_intent.canceled": {
        const pi = event.data.object as { id: string };
        await supabase
          .from("payments")
          .update({ status: "cancelled", updated_at: now })
          .eq("stripe_payment_intent_id", pi.id);
        break;
      }

      case "account.updated": {
        const account = event.data.object as {
          id: string;
          charges_enabled?: boolean;
          payouts_enabled?: boolean;
          details_submitted?: boolean;
        };
        const onboarded =
          account.charges_enabled === true &&
          account.payouts_enabled === true &&
          account.details_submitted === true;

        await supabase
          .from("professional_profiles")
          .update({ stripe_onboarding_complete: onboarded, updated_at: now })
          .eq("stripe_account_id", account.id);
        break;
      }

      // payout.paid will eventually populate payments.payout_at. Skipped for MVP
      // because it requires listening on connected accounts (Stripe-Account
      // header) and matching balance_transactions back to PaymentIntents.

      default:
        // Unhandled — fine to ignore. Stripe sends many event types.
        break;
    }
  } catch (err) {
    const msg = err instanceof Error ? err.message : "unknown";
    console.error(`Error handling ${event.type} (${event.id}):`, msg);
    // Return 200 anyway — surfacing 500s causes Stripe to retry indefinitely
    // on logic bugs. Inspect logs and replay manually if needed.
  }

  return new Response("ok", { status: 200 });
});
