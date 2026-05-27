import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { stripe } from "../_shared/stripe.ts";
import { adminClient } from "../_shared/supabase.ts";
import { authenticate } from "../_shared/auth.ts";
import { json, errorResponse } from "../_shared/responses.ts";
import { handleOptions } from "../_shared/cors.ts";

const PLATFORM_FEE_PERCENT = Number(Deno.env.get("PLATFORM_FEE_PERCENT") ?? "10");

serve(async (req) => {
  const optionsResponse = handleOptions(req);
  if (optionsResponse) return optionsResponse;

  const auth = await authenticate(req);
  if (!auth.ok) return errorResponse(auth.message, auth.status);

  let body: { request_id?: string; amount_to_capture?: number };
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body");
  }

  const { request_id, amount_to_capture } = body;
  if (!request_id || typeof amount_to_capture !== "number" || amount_to_capture <= 0) {
    return errorResponse("request_id and a positive amount_to_capture (euros) are required");
  }

  const supabase = adminClient();

  const { data: request } = await supabase
    .from("service_requests")
    .select("id, pro_id, status")
    .eq("id", request_id)
    .single();

  if (!request) return errorResponse("Service request not found", 404);
  if (request.pro_id !== auth.user.id) return errorResponse("Forbidden", 403);
  if (request.status === "completed") return errorResponse("Job already completed", 409);
  if (request.status === "cancelled") return errorResponse("Job is cancelled", 409);

  const { data: payment } = await supabase
    .from("payments")
    .select("id, status, amount_authorised, stripe_payment_intent_id")
    .eq("request_id", request_id)
    .single();

  if (!payment) return errorResponse("No payment for this request", 404);
  if (payment.status !== "authorised") {
    return errorResponse(`Cannot capture — payment is ${payment.status}`, 409);
  }

  const amountAuthorised = Number(payment.amount_authorised);
  if (amount_to_capture > amountAuthorised) {
    return errorResponse(
      `Capture amount (${amount_to_capture}) exceeds authorised amount (${amountAuthorised})`,
      400,
    );
  }

  const amountCents = Math.round(amount_to_capture * 100);

  let captured;
  try {
    captured = await stripe.paymentIntents.capture(payment.stripe_payment_intent_id, {
      amount_to_capture: amountCents,
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : "Stripe error";
    return errorResponse(`Capture failed: ${msg}`, 402);
  }

  const platformFee = Math.round(amount_to_capture * PLATFORM_FEE_PERCENT) / 100;
  const now = new Date().toISOString();

  const { error: payErr } = await supabase
    .from("payments")
    .update({
      // pro_id is null until now — the payment was authorised at request time
      // before any pro was assigned. Stamp it on completion.
      pro_id: request.pro_id,
      status: "captured",
      amount_charged: amount_to_capture,
      platform_fee: platformFee,
      captured_at: now,
      updated_at: now,
    })
    .eq("id", payment.id);

  if (payErr) {
    return errorResponse(`Capture succeeded in Stripe but DB update failed: ${payErr.message}`, 500);
  }

  const { error: reqErr } = await supabase
    .from("service_requests")
    .update({
      status: "completed",
      completed_at: now,
      updated_at: now,
    })
    .eq("id", request_id);

  if (reqErr) {
    return errorResponse(`Captured but failed to mark request completed: ${reqErr.message}`, 500);
  }

  return json({
    status: captured.status,
    amount_charged: amount_to_capture,
    platform_fee: platformFee,
  });
});
