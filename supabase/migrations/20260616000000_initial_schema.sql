-- =============================================================================
-- Fieldify — Initial Schema
-- Run this in the Supabase SQL Editor (or via `supabase db push`) on a fresh
-- project to recreate the full database structure.
--
-- Prerequisites:
--   • PostGIS extension (enabled below)
--   • pgcrypto extension (for gen_random_uuid on PG < 13; PG 15 has it built-in)
--   • auth.users table managed by Supabase Auth (do NOT create it manually)
--
-- After running this file, run seed.sql to populate reference data (trades).
-- =============================================================================

-- ─── Extensions ───────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS postgis;

-- ─── Shared trigger: keep updated_at current ──────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- =============================================================================
-- TABLES (in dependency order)
-- =============================================================================

-- ─── profiles ─────────────────────────────────────────────────────────────────
-- One row per registered user, created automatically by the trigger below.
CREATE TABLE public.profiles (
  id                    uuid        NOT NULL,
  role                  text        NOT NULL CHECK (role = ANY (ARRAY['client','professional','admin'])),
  full_name             text        NOT NULL,
  phone                 text,
  avatar_url            text,
  stripe_customer_id    text        UNIQUE,
  notifications_enabled boolean     DEFAULT true,
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Auto-create a profile row whenever a new user registers via Supabase Auth.
-- The Flutter app must pass `full_name` and `role` in raw_user_meta_data at
-- sign-up time: Supabase.instance.client.auth.signUp(data: {'full_name': ..., 'role': ...})
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'client')
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ─── trades ───────────────────────────────────────────────────────────────────
-- Platform-managed reference table. Seeded via seed.sql.
CREATE TABLE public.trades (
  id            serial      NOT NULL,
  slug          text        NOT NULL UNIQUE,
  display_name  text        NOT NULL,
  standard_rate numeric     NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT trades_pkey PRIMARY KEY (id)
);

ALTER TABLE public.trades ENABLE ROW LEVEL SECURITY;

-- ─── professional_profiles ────────────────────────────────────────────────────
-- Extended data for users with role = 'professional'. No row means the profile
-- is a client or an admin.
CREATE TABLE public.professional_profiles (
  id                        uuid        NOT NULL DEFAULT gen_random_uuid(),
  profile_id                uuid        NOT NULL UNIQUE,
  trade_id                  integer     NOT NULL,
  nif                       text        NOT NULL UNIQUE,
  verification_status       text        NOT NULL DEFAULT 'pending'
    CHECK (verification_status = ANY (ARRAY['pending','approved','rejected'])),
  rejection_reason          text,
  bio                       text,
  is_available              boolean     NOT NULL DEFAULT false,
  service_radius_km         integer     NOT NULL DEFAULT 20,
  base_location             geography(point, 4326),
  -- lat/lng are derived from base_location and kept in sync automatically.
  lat                       double precision GENERATED ALWAYS AS (ST_Y(base_location::geometry)) STORED,
  lng                       double precision GENERATED ALWAYS AS (ST_X(base_location::geometry)) STORED,
  verified_at               timestamptz,
  credential_urls           text[]      NOT NULL DEFAULT '{}',
  stripe_account_id         text        UNIQUE,
  stripe_onboarding_complete boolean    NOT NULL DEFAULT false,
  created_at                timestamptz NOT NULL DEFAULT now(),
  updated_at                timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT professional_profiles_pkey PRIMARY KEY (id),
  CONSTRAINT professional_profiles_profile_id_fkey
    FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON DELETE CASCADE,
  CONSTRAINT professional_profiles_trade_id_fkey
    FOREIGN KEY (trade_id) REFERENCES public.trades(id)
);

ALTER TABLE public.professional_profiles ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER professional_profiles_updated_at
  BEFORE UPDATE ON public.professional_profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ─── availability_schedules ───────────────────────────────────────────────────
-- Weekly schedule per professional. One row per active day (0 = Sunday … 6 = Saturday).
-- A professional must also have is_available = true on their profile to appear in matching.
CREATE TABLE public.availability_schedules (
  id           uuid      NOT NULL DEFAULT gen_random_uuid(),
  pro_id       uuid      NOT NULL,
  day_of_week  smallint  NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
  start_time   time      NOT NULL,
  end_time     time      NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT availability_schedules_pkey PRIMARY KEY (id),
  CONSTRAINT availability_schedules_pro_id_fkey
    FOREIGN KEY (pro_id) REFERENCES public.professional_profiles(id) ON DELETE CASCADE
);

ALTER TABLE public.availability_schedules ENABLE ROW LEVEL SECURITY;

-- ─── service_requests ─────────────────────────────────────────────────────────
-- Central entity. Status progresses: pending → accepted → on_my_way →
-- in_progress → completed. cancelled is reachable from most states.
CREATE TABLE public.service_requests (
  id              uuid        NOT NULL DEFAULT gen_random_uuid(),
  client_id       uuid        NOT NULL,
  trade_id        integer     NOT NULL,
  pro_id          uuid,
  title           text        NOT NULL,
  description     text        NOT NULL,
  photo_urls      text[]      NOT NULL DEFAULT '{}',
  location        geography(point, 4326) NOT NULL,
  lat             double precision GENERATED ALWAYS AS (ST_Y(location::geometry)) STORED,
  lng             double precision GENERATED ALWAYS AS (ST_X(location::geometry)) STORED,
  address_text    text        NOT NULL,
  status          text        NOT NULL DEFAULT 'pending'
    CHECK (status = ANY (ARRAY['pending','accepted','on_my_way','in_progress','completed','cancelled'])),
  scheduled_at    timestamptz,
  accepted_at     timestamptz,
  on_my_way_at    timestamptz,
  started_at      timestamptz,
  completed_at    timestamptz,
  cancelled_at    timestamptz,
  cancel_reason   text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT service_requests_pkey PRIMARY KEY (id),
  CONSTRAINT service_requests_client_id_fkey
    FOREIGN KEY (client_id) REFERENCES public.profiles(id),
  CONSTRAINT service_requests_pro_id_fkey
    FOREIGN KEY (pro_id) REFERENCES public.profiles(id),
  CONSTRAINT service_requests_trade_id_fkey
    FOREIGN KEY (trade_id) REFERENCES public.trades(id)
);

ALTER TABLE public.service_requests ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER service_requests_updated_at
  BEFORE UPDATE ON public.service_requests
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ─── service_request_rejections ───────────────────────────────────────────────
-- Records which professionals have dismissed a pending request from their feed.
-- The request stays visible to other professionals; only this professional's
-- view is filtered.
CREATE TABLE public.service_request_rejections (
  pro_id      uuid        NOT NULL,
  request_id  uuid        NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT service_request_rejections_pkey PRIMARY KEY (pro_id, request_id),
  CONSTRAINT service_request_rejections_pro_id_fkey
    FOREIGN KEY (pro_id) REFERENCES public.profiles(id),
  CONSTRAINT service_request_rejections_request_id_fkey
    FOREIGN KEY (request_id) REFERENCES public.service_requests(id) ON DELETE CASCADE
);

ALTER TABLE public.service_request_rejections ENABLE ROW LEVEL SECURITY;

-- ─── payment_methods ──────────────────────────────────────────────────────────
-- Saved cards belonging to a client, backed by a Stripe PaymentMethod object.
-- Populated by the stripe-webhook Edge Function on setup_intent.succeeded.
CREATE TABLE public.payment_methods (
  id                        uuid        NOT NULL DEFAULT gen_random_uuid(),
  profile_id                uuid        NOT NULL,
  stripe_payment_method_id  text        NOT NULL UNIQUE,
  card_brand                text,
  card_last4                text,
  is_default                boolean     NOT NULL DEFAULT false,
  created_at                timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT payment_methods_pkey PRIMARY KEY (id),
  CONSTRAINT payment_methods_profile_id_fkey
    FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON DELETE CASCADE
);

ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;

-- ─── payments ─────────────────────────────────────────────────────────────────
-- Created when a professional taps "on my way". Tracks the full Stripe
-- authorize-and-capture lifecycle. pro_id is nullable: it mirrors the
-- service_request's pro_id and is set when the job is accepted.
CREATE TABLE public.payments (
  id                        uuid        NOT NULL DEFAULT gen_random_uuid(),
  request_id                uuid        NOT NULL UNIQUE,
  client_id                 uuid        NOT NULL,
  pro_id                    uuid,
  payment_method_id         uuid        NOT NULL,
  stripe_payment_intent_id  text        NOT NULL UNIQUE,
  amount_authorised         numeric     NOT NULL,
  amount_charged            numeric,
  platform_fee              numeric,
  currency                  text        NOT NULL DEFAULT 'eur',
  status                    text        NOT NULL DEFAULT 'authorised'
    CHECK (status = ANY (ARRAY['authorised','captured','cancelled','refunded'])),
  authorised_at             timestamptz,
  captured_at               timestamptz,
  payout_at                 timestamptz,
  created_at                timestamptz NOT NULL DEFAULT now(),
  updated_at                timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT payments_pkey PRIMARY KEY (id),
  CONSTRAINT payments_request_id_fkey
    FOREIGN KEY (request_id) REFERENCES public.service_requests(id),
  CONSTRAINT payments_client_id_fkey
    FOREIGN KEY (client_id) REFERENCES public.profiles(id),
  CONSTRAINT payments_pro_id_fkey
    FOREIGN KEY (pro_id) REFERENCES public.profiles(id),
  CONSTRAINT payments_payment_method_id_fkey
    FOREIGN KEY (payment_method_id) REFERENCES public.payment_methods(id)
);

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER payments_updated_at
  BEFORE UPDATE ON public.payments
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ─── reviews ──────────────────────────────────────────────────────────────────
-- One review per completed job, written by the client.
CREATE TABLE public.reviews (
  id          uuid      NOT NULL DEFAULT gen_random_uuid(),
  request_id  uuid      NOT NULL UNIQUE,
  client_id   uuid      NOT NULL,
  pro_id      uuid      NOT NULL,
  rating      smallint  NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment     text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT reviews_pkey PRIMARY KEY (id),
  CONSTRAINT reviews_request_id_fkey
    FOREIGN KEY (request_id) REFERENCES public.service_requests(id),
  CONSTRAINT reviews_client_id_fkey
    FOREIGN KEY (client_id) REFERENCES public.profiles(id),
  CONSTRAINT reviews_pro_id_fkey
    FOREIGN KEY (pro_id) REFERENCES public.profiles(id)
);

ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- ─── messages ─────────────────────────────────────────────────────────────────
-- Chat messages scoped to a service request. type = 'text' for normal chat;
-- type = 'reschedule' carries a reschedule proposal in reschedule_proposed_at
-- and its lifecycle in reschedule_status / reschedule_responded_at.
CREATE TABLE public.messages (
  id                      uuid        NOT NULL DEFAULT gen_random_uuid(),
  request_id              uuid        NOT NULL,
  sender_id               uuid        NOT NULL,
  content                 text        NOT NULL,
  type                    text        NOT NULL DEFAULT 'text'
    CHECK (type = ANY (ARRAY['text','reschedule'])),
  reschedule_proposed_at  timestamptz,
  reschedule_status       text
    CHECK (reschedule_status = ANY (ARRAY['pending','accepted','rejected'])),
  reschedule_responded_at timestamptz,
  read_at                 timestamptz,
  created_at              timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT messages_pkey PRIMARY KEY (id),
  CONSTRAINT messages_request_id_fkey
    FOREIGN KEY (request_id) REFERENCES public.service_requests(id) ON DELETE CASCADE,
  CONSTRAINT messages_sender_id_fkey
    FOREIGN KEY (sender_id) REFERENCES public.profiles(id)
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- ─── fcm_tokens ───────────────────────────────────────────────────────────────
-- FCM device tokens. One user can have multiple tokens (multiple devices).
-- The send-push-notification Edge Function reads from this table to deliver
-- push notifications via Firebase Cloud Messaging.
CREATE TABLE public.fcm_tokens (
  id          uuid        NOT NULL DEFAULT gen_random_uuid(),
  user_id     uuid        NOT NULL,
  token       text        NOT NULL,
  created_at  timestamptz DEFAULT now(),
  CONSTRAINT fcm_tokens_pkey PRIMARY KEY (id),
  CONSTRAINT fcm_tokens_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- VIEWS
-- =============================================================================

-- Aggregated rating per professional. Used instead of a denormalised avg_rating
-- column to avoid triggers and keep the data model normalised.
CREATE VIEW public.pro_ratings AS
SELECT
  pro_id,
  COUNT(*)::integer        AS review_count,
  ROUND(AVG(rating)::numeric, 2) AS avg_rating
FROM public.reviews
GROUP BY pro_id;

-- =============================================================================
-- RLS POLICIES
-- =============================================================================
-- Row-Level Security is enabled on every table above. Policies are managed
-- separately in the Supabase dashboard or via additional migration files.
-- Without policies, authenticated users will be denied all access by default.
--
-- Minimum policies needed to get the app working:
--   profiles        — users can read/update their own row
--   trades          — all authenticated users can read
--   professional_profiles — pros can CRUD their own; clients can read approved ones
--   service_requests      — clients own theirs; pros see pending ones matching their trade
--   ... (see Supabase dashboard → Authentication → Policies for the full set)
