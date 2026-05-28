import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";

let _instance: Stripe | null = null;

function init(): Stripe {
  const key = Deno.env.get("STRIPE_SECRET_KEY");
  if (!key) {
    throw new Error("STRIPE_SECRET_KEY environment variable is not set");
  }
  return new Stripe(key, {
    apiVersion: "2024-06-20",
    httpClient: Stripe.createFetchHttpClient(),
  });
}

// Lazy proxy: keeps the `import { stripe }` API but defers env-var lookup
// until first method access. Top-level throws fail Supabase's deploy-time
// load check even when the secret is correctly set in production.
export const stripe = new Proxy({} as Stripe, {
  get(_target, prop) {
    if (!_instance) _instance = init();
    return Reflect.get(_instance, prop);
  },
});
