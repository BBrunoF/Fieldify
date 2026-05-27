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

  const { data: profile, error: profileError } = await supabase
    .from("profiles")
    .select("id, full_name, stripe_customer_id")
    .eq("id", auth.user.id)
    .single();

  if (profileError || !profile) {
    return errorResponse("Profile not found", 404);
  }

  let customerId = profile.stripe_customer_id;
  if (!customerId) {
    const customer = await stripe.customers.create({
      email: auth.user.email,
      name: profile.full_name,
      metadata: { profile_id: profile.id },
    });
    customerId = customer.id;

    const { error: updateError } = await supabase
      .from("profiles")
      .update({ stripe_customer_id: customerId })
      .eq("id", profile.id);

    if (updateError) {
      return errorResponse(`Failed to save Stripe customer: ${updateError.message}`, 500);
    }
  }

  const setupIntent = await stripe.setupIntents.create({
    customer: customerId,
    payment_method_types: ["card"],
    usage: "off_session",
  });

  return json({ client_secret: setupIntent.client_secret });
});
