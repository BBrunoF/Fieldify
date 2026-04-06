# Physical Architecture

The Fieldify physical architecture is represented as a UML deployment diagram and describes the runtime environment of the system — the actual nodes, services, and protocols through which the platform operates. It maps directly onto the technology decisions recorded in the architecture decision document.

## Mobile device

The client-side runtime is a Flutter application installed on iOS or Android devices. It is the only entry point for both clients and professionals. The Google Maps SDK is initialised within the app and makes requests directly to the Google Maps Platform API using a publishable key, handling map rendering and geocoding entirely client-side without routing through any Fieldify-controlled server.

The Flutter app communicates with the Supabase cloud over two channels: HTTPS for database queries, authentication, file access, and edge function invocations; and a persistent WebSocket connection (WSS) to Supabase Realtime for live job status updates and incoming job notifications. This eliminates the need for polling — the app subscribes to specific rows and receives changes as they happen.

## Supabase cloud

Supabase is the sole backend platform, consolidating four runtime concerns under a single managed service.

Supabase Auth, built on GoTrue, handles session management and JWT issuance. Every request from the Flutter app carries a JWT as a Bearer token, which Supabase validates before executing any database or storage operation. This token is also the mechanism through which Row-Level Security policies identify the acting user — the `auth.uid()` function is available in every RLS policy, scoping data access without any additional middleware.

The Postgres database stores all domain data: users, professional profiles, jobs, messages, payments, reviews, credentials, and file references. RLS policies enforce access control at the database level, providing a security boundary that is independent of application logic. Database triggers are used for specific state management — most notably, a trigger on `auth.users` insertion automatically creates the corresponding `profiles` row from registration metadata, and outbound webhook calls to Edge Functions are fired on job status transitions. Professional ratings are not maintained by a trigger; they are computed on demand via a database view that aggregates across all `reviews` rows for a given professional.

Supabase Realtime listens to Postgres's write-ahead log and broadcasts row-level changes to subscribed clients over WebSocket. Subscriptions are SQL-filtered — a professional's app subscribes only to job requests matching their trade and location, and a client's app subscribes only to status changes on their own jobs. This makes the real-time layer precise and efficient rather than broadcasting all changes to all connected clients.

Supabase Storage holds binary objects — job photos uploaded by clients, credential documents uploaded by professionals, and profile pictures. Files are referenced by storage path in the database and accessed via HTTPS. Access control is enforced through RLS policies that mirror those on the database, using the same `auth.uid()` context.

Edge Functions are server-side TypeScript functions running on Deno, deployed and managed within the Supabase platform. They serve two purposes: handling Stripe payment operations (authorisation, capture, refund, webhook processing) with the Stripe secret key stored as an environment variable; and dispatching push notifications to FCM on job lifecycle events. Critically, the Flutter app never calls the Stripe API directly — all payment operations are proxied through Edge Functions to ensure that secret credentials are never present in the client application.

## External services

Stripe handles all financial operations. The Flutter app initiates payment flows by calling an Edge Function, which then communicates with the Stripe Payments API server-to-server. Stripe sends webhook events back to a dedicated Edge Function endpoint — for example, to confirm payment capture or flag a failed authorisation — which then updates the corresponding `Payment` row in Postgres.

Firebase Cloud Messaging handles push notification delivery to mobile devices. Edge Functions dispatch notification payloads to the FCM HTTP v1 API, which manages the last-mile delivery to the target device. Device token storage and the notifications table are planned additions to the schema, deferred until FCM integration is implemented.

The Google Maps Platform provides geocoding and map tile rendering. As noted above, this integration is entirely client-side and does not interact with any Fieldify backend service.

An SMTP provider handles transactional email — account verification messages and significant platform events. Email dispatch is triggered through the Notification Service via Edge Functions.