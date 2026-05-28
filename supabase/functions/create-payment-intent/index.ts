import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { stripe } from "../_shared/stripe.ts";
import { adminClient } from "../_shared/supabase.ts";
import { authenticate } from "../_shared/auth.ts";
import { json, errorResponse } from "../_shared/responses.ts";
import { handleOptions } from "../_shared/cors.ts";

const MAX_JOB_HOURS = Number(Deno.env.get("MAX_JOB_HOURS") ?? "8");

// Authorisation happens at REQUEST time, before any pro is assigned. We place
// a manual-capture hold on the client's card for the maximum a job could cost
// (rate × MAX_JOB_HOURS). No Stripe Connect / transfer is involved here — the
// pro payout (if any) is handled separately at capture time.
serve(async (req) => {
  const optionsResponse = handleOptions(req);
  if (optionsResponse) return optionsResponse;

  const auth = await authenticate(req);
  if (!auth.ok) return errorResponse(auth.message, auth.status);

  let body: { request_id?: string; payment_method_id?: string };
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body");
  }

  const { request_id, payment_method_id } = body;
  if (!request_id || !payment_method_id) {
    return errorResponse("request_id and payment_method_id are required");
  }

  const supabase = adminClient();

  const { data: request, error: requestError } = await supabase
    .from("service_requests")
    .select("id, client_id, trade_id, status")
    .eq("id", request_id)
    .single();

  if (requestError || !request) return errorResponse("Service request not found", 404);
  if (request.client_id !== auth.user.id) return errorResponse("Forbidden", 403);

  const { data: existingPayment } = await supabase
    .from("payments")
    .select("id, status")
    .eq("request_id", request_id)
    .maybeSingle();

  if (existingPayment) {
    return errorResponse(`Payment already exists for this request (status: ${existingPayment.status})`, 409);
  }

  const { data: clientProfile } = await supabase
    .from("profiles")
    .select("stripe_customer_id")
    .eq("id", auth.user.id)
    .single();

  if (!clientProfile?.stripe_customer_id) {
    return errorResponse("Client has no Stripe customer — set up a card first", 400);
  }

  const { data: paymentMethod } = await supabase
    .from("payment_methods")
    .select("id, stripe_payment_method_id, profile_id")
    .eq("id", payment_method_id)
    .single();

  if (!paymentMethod || paymentMethod.profile_id !== auth.user.id) {
    return errorResponse("Payment method not found", 404);
  }

  const { data: trade } = await supabase
    .from("trades")
    .select("standard_rate")
    .eq("id", request.trade_id)
    .single();

  if (!trade) return errorResponse("Trade not found", 404);

  // Stripe expects integer minor units (cents). DB stores `numeric` euros.
  const rateEuros = Number(trade.standard_rate);
  const amountAuthorisedEuros = rateEuros * MAX_JOB_HOURS;
  const amountAuthorisedCents = Math.round(amountAuthorisedEuros * 100);

  let paymentIntent;
  try {
    paymentIntent = await stripe.paymentIntents.create({
      amount: amountAuthorisedCents,
      currency: "eur",
      customer: clientProfile.stripe_customer_id,
      payment_method: paymentMethod.stripe_payment_method_id,
      capture_method: "manual",
      confirm: true,
      off_session: true,
      metadata: {
        request_id,
        client_id: auth.user.id,
      },
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : "Stripe error";
    return errorResponse(`Failed to authorise payment: ${msg}`, 402);
  }

  const { error: insertError } = await supabase.from("payments").insert({
    request_id,
    client_id: auth.user.id,
    payment_method_id: paymentMethod.id,
    stripe_payment_intent_id: paymentIntent.id,
    amount_authorised: amountAuthorisedEuros,
    currency: "eur",
    status: "authorised",
    authorised_at: new Date().toISOString(),
  });

  if (insertError) {
    await stripe.paymentIntents.cancel(paymentIntent.id).catch(() => {});
    return errorResponse(`Failed to save payment: ${insertError.message}`, 500);
  }

  return json({
    payment_intent_id: paymentIntent.id,
    status: paymentIntent.status,
    amount_authorised: amountAuthorisedEuros,
  });
});
