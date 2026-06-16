-- =============================================================================
-- Fieldify — Seed Data
-- Run after 20260616000000_initial_schema.sql.
-- Safe to re-run: ON CONFLICT DO NOTHING skips existing rows.
-- =============================================================================

-- ─── Trades ───────────────────────────────────────────────────────────────────
-- standard_rate is the hourly rate in EUR used for billing calculations.
INSERT INTO public.trades (slug, display_name, standard_rate) VALUES
  ('plumbing',   'Plumbing',   45.00),
  ('electrical', 'Electrical', 55.00),
  ('carpentry',  'Carpentry',  40.00),
  ('hvac',       'HVAC',       60.00),
  ('painting',   'Painting',   35.00),
  ('other',      'Other',      38.00)
ON CONFLICT (slug) DO NOTHING;

-- ─── Storage buckets ──────────────────────────────────────────────────────────
-- Create these via the Supabase dashboard (Storage → New bucket) or Supabase CLI.
-- Both buckets should be PRIVATE with RLS policies scoped to auth.uid().
--
--   service-request-photos  — job photos uploaded by clients
--   credential-documents    — onboarding documents uploaded by professionals
--   avatars                 — profile pictures (public read, owner write)
--
-- Supabase CLI equivalent:
--   supabase storage create service-request-photos --private
--   supabase storage create credential-documents   --private
--   supabase storage create avatars

-- ─── Dev / QA test accounts ───────────────────────────────────────────────────
-- Create these manually via the Supabase dashboard (Authentication → Users → Add user)
-- or via the app's registration flow, then note the UUIDs if you need to seed jobs.
--
--   client@client.com   / clientclient   → role: client
--   pro@pro.com         / proprofessional → role: professional
--                         (then create a professional_profiles row for this user)
