import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { stripe } from "../_shared/stripe.ts";
import { adminClient } from "../_shared/supabase.ts";
import { authenticate } from "../_shared/auth.ts";
import { json, errorResponse } from "../_shared/responses.ts";
import { handleOptions } from "../_shared/cors.ts";

serve(async (req) => {
  const optionsResponse = handleOptions(req);
  if (optionsResponse) return optionsResponse;

  const auth = await authenticate(req);
  if (!auth.ok) return errorResponse(auth.message, auth.status);

  const supabase = adminClient();

  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", auth.user.id)
    .single();

  if (profile?.role !== "professional") {
    return errorResponse("Only professionals can connect Stripe", 403);
  }

  const { data: proProfile, error: proError } = await supabase
    .from("professional_profiles")
    .select("id, stripe_account_id")
    .eq("profile_id", auth.user.id)
    .single();

  if (proError || !proProfile) {
    return errorResponse("Professional profile not found", 404);
  }

  const country = Deno.env.get("STRIPE_CONNECT_COUNTRY") ?? "PT";

  let accountId = proProfile.stripe_account_id;
  if (!accountId) {
    try {
      const account = await stripe.accounts.create({
        type: "express",
        country,
        email: auth.user.email,
        capabilities: {
          card_payments: { requested: true },
          transfers: { requested: true },
        },
        metadata: { professional_profile_id: proProfile.id },
      });
      accountId = account.id;
    } catch (err) {
      const msg = err instanceof Error ? err.message : "Stripe error";
      console.error("stripe.accounts.create failed:", msg);
      return errorResponse(`Stripe account creation failed: ${msg}`, 502);
    }

    const { error: updateError } = await supabase
      .from("professional_profiles")
      .update({ stripe_account_id: accountId })
      .eq("id", proProfile.id);

    if (updateError) {
      return errorResponse(`Failed to save Stripe account: ${updateError.message}`, 500);
    }
  }

  // TEMP DIAGNOSTIC: dump why Stripe might refuse to onboard this account.
  try {
    const acct = await stripe.accounts.retrieve(accountId);
    console.log("ACCOUNT DIAG", JSON.stringify({
      id: acct.id,
      country: acct.country,
      type: acct.type,
      charges_enabled: acct.charges_enabled,
      payouts_enabled: acct.payouts_enabled,
      details_submitted: acct.details_submitted,
      disabled_reason: acct.requirements?.disabled_reason,
      currently_due: acct.requirements?.currently_due,
      past_due: acct.requirements?.past_due,
      errors: acct.requirements?.errors,
      capabilities: acct.capabilities,
    }));
  } catch (e) {
    console.error("ACCOUNT DIAG failed:", e instanceof Error ? e.message : e);
  }

  const refreshUrl = Deno.env.get("STRIPE_CONNECT_REFRESH_URL")
    ?? "https://fieldify.app/stripe/refresh";
  const returnUrl = Deno.env.get("STRIPE_CONNECT_RETURN_URL")
    ?? "https://fieldify.app/stripe/return";

  let accountLink;
  try {
    accountLink = await stripe.accountLinks.create({
      account: accountId,
      refresh_url: refreshUrl,
      return_url: returnUrl,
      type: "account_onboarding",
      // Force the hosted page to surface exactly the fields Stripe still
      // needs (address, ID, etc.) instead of ending onboarding early and
      // leaving the account "restricted / currently_due".
      collection_options: { fields: "currently_due" },
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : "Stripe error";
    console.error("stripe.accountLinks.create failed:", msg);
    return errorResponse(`Stripe account link creation failed: ${msg}`, 502);
  }

  return json({ onboarding_url: accountLink.url });
});
