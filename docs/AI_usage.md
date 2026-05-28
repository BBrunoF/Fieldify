# Responsible Use of Agentic AI for Software Development

## Tools Used
- Claude (claude.ai)
- GitHub Copilot
- Gemini (Google)

## Usage Log

### Sprint 1

---

#### US01, US02, US03 — Feature-First Clean Architecture & Layer Separation
- **Tool:** Claude (Claude Code)
- **Prompt:** "Restructure this Flutter project to a feature-first clean architecture" and "Separate data, logic, and UI layers properly across the auth, request, and home features."
- **Output:** Reorganized `lib/` into `core/`, `features/{auth,home,request}/`, and `shared/` directories. Created/split 15+ files: extracted `FieldifyColors` → `core/theme/app_colors.dart`, Supabase global → `core/supabase/supabase_client.dart`, `AuthGate` → `core/routing/app_router.dart`; implemented `AuthRepository` (catches `AuthException` → `AuthFailure`), `AuthController` (ChangeNotifier), `RequestRepository`, `RequestController`, `Trade` model, `TradesRepository`; extracted `BottomNav`/`NavIconPainter` to `shared/widgets/bottom_nav.dart`; updated all screen files to use controllers instead of direct Supabase calls. `flutter analyze` passes with 0 issues.
- **Commit:** [`8ac02ab`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/8ac02ab) (branch `fileRestructure`, merged via [PR #47](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/pull/47))

#### US14 — Feature-first role split & incoming jobs hardening
- **Tool:** Claude (Claude Code)
- **Prompt:** "after this restructure for the file system my colleague added incoming jobs for the professional side, now do u think this follows the feature first architecture weve implemented" → followed by "separate further features from pro side and cliente side. features that both have its fine keep them where they are" → "change jobs to incoming jobs" → "tacke 1 and 3" (rejection filter in SQL + optimistic concurrency on accept) → "it should only list jobs which its trade id is the same as the professional trade id"
- **Output:**
  - Restructured `lib/features/request/` into `lib/features/client/request/` and `lib/features/pro/incoming_jobs/` using `git mv` (history preserved). Updated all relative imports (one level deeper) and `home_screen.dart` references.
  - Hardened `IncomingJobsService`:
    - Added trade filter: look up `professional_profiles.trade_id` by `profile_id = auth.uid()`, throw `ProfessionalProfileMissingException` if absent, then `.eq('trade_id', tradeId)` on `service_requests`.
    - Pushed rejection filter from Dart to SQL: `query.not('id', 'in', '(${rejectedIds.join(',')})')` instead of client-side filtering.
    - Optimistic concurrency on accept: `.update({...}).eq('id', requestId).eq('status', 'pending').select()` — empty result throws `JobAlreadyTakenException`, preventing two pros from accepting the same job.
  - Wrapped new exceptions in `IncomingJobsRepository` as `IncomingJobsFailure`.
  - Debugged empty-list issue — root cause was missing RLS policy on `professional_profiles`; added `USING (auth.uid() = profile_id)` SELECT policy.
  - Fixed `patrol_test/request_test.dart` imports to new paths; resolved stale kernel depfile via `flutter clean && flutter pub get`.
  - Resolved GitHub "Can't automatically merge" on PR by merging `main` into `fileRestructure` with `-X ours`, then manually removed duplicated `_LogoutButton`, duplicate `requestButtonKey` param, and restored `main.dart` bootstrap bracing.
- **Commit:** (branch `fileRestructure`, merged via [PR #47](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/pull/47))

#### US03 — Dynamic service trades
- **Tool:** Claude (Claude Code)
- **Prompt:** "Ok mas eu queria listar as trades dinamicamente sobre a view. Segues a logica da feature de forma a que as trades sejam listadas dinamicamente, e nao em hard code."
- **Output:** Extended the request feature to load trades from Supabase instead of hardcoding them: added `getTrades` to `RequestService` and `RequestRepository`, added `loadTrades`/`trades` state to `RequestController`, rewrote step 1 of `request_screen.dart` to render from the controller, updated `Trade` model to match the real schema (`slug`, `display_name`, `standard_rate`), deleted the dead `TradesRepository`, and updated `request_controller_test.dart`, `request_screen_test.dart`, `trade_model_test.dart`.
- **Commit:** [2a224f3](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/2a224f3210b62afcda724dbc62e2c18023aad879)

#### US03 — Photo upload in service requests
- **Tool:** Claude (Claude Code)
- **Prompt:** "now how do i in request job had the possibility of actually sending photos" / "quero galeria e camera, max de photos pode ser tipo 3"
- **Output:** Implemented client-side photo upload (up to 3, camera or gallery) to a private Supabase Storage bucket with RLS. Added `uploadPhoto` to `RequestService`, `uploadPhotos` to `RequestRepository`, `photos`/`requestIdGenerator` parameters to `RequestController.submit` (client-side UUID so photos can be uploaded before the DB row exists), and a photo picker UI in step 2 of `request_screen.dart`. Updated `pubspec.yaml` (`image_picker`, `flutter_image_compress`, `uuid`), iOS `Info.plist`, Android `AndroidManifest.xml`; hardened `patrol_test/request_test.dart` to wait for async trade loading.
- **Commit:** [2a224f3](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/2a224f3210b62afcda724dbc62e2c18023aad879)

#### US05, US06, US15, US17 — Job Detail feature — tests & polish
- **Tool:** Claude (Claude Code)
- **Prompt:** "can you make UATs in patrol and unit tests based on this feature"
- **Output:** Added unit/widget tests for the `job_detail` feature (model, repository, controller, screen) under `test/features/shared/job_detail/`, plus a Patrol UAT at `patrol_test/job_detail_test.dart` covering open-detail, pending-state rendering, client cancel, and back navigation. Fixed a Material-ancestor test failure in `IncomingJobCard` by swapping `InkWell` for `GestureDetector`. Added a `jobDetailBackButton` key to the top bar for the UAT.
- **Commit:** [6f0e03e](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/6f0e03e)

#### US14 — Domain model update: ServiceRequestRejection
- **Tool:** Claude (Claude Code)
- **Prompt:** "also can u update the uml to include this table" / "ok now also update the description to add that table"
- **Output:** Added `service_request_rejections` entity (composite PK `pro_id`, `request_id`) with FK relationships to `service_requests` and `profiles` in `docs/fieldify-domain-model.puml`, and a matching explanatory paragraph in `docs/fieldify-domain-model-description.md`.
- **Commit:** [53e1bc7](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/53e1bc7), [3a46ddb](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/3a46ddb)



---

### Sprint 2

---

#### US10, US15, US17, US05 — Code Structure Refactor & Architecture Fixes
- **Tool:** Claude (Claude Code)
- **Prompt:** "create a new branch from main called codeStructureMaintenance, because once merged i want to fix some things when it comes to the code structure"
- **Output:** Massive 68-file refactor across the entire codebase: consolidated `pro/accepted_jobs/` and `pro/incoming_jobs/` into a single `pro/jobs/` feature with unified `ProJobsController`, `ProJob` model, `ProJobsRepository`, and `ProJobsService`; created missing `home/` pipeline (`HomeController` → `HomeRepository` → `HomeService`) removing direct Supabase calls from `home_screen.dart`; removed Supabase imports from `client_home_screen.dart` (now uses `ProfileController`) and `home_action_buttons.dart` (now purely UI); extracted status-to-color/label mapping from `ClientJobCard` into `JobStatusStyle` utility; extracted trade icon mapping into `TradeIconMapper`; created `date_format_utils.dart` in shared utils; updated all import paths and all corresponding unit, widget, and Patrol tests.
- **Commit:** [`61c63ff`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/61c63ff) (branch `codeStructureMaintenance`, merged via [PR #55](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/pull/55))

#### US15 — Google Maps & Geolocation Integration
- **Tool:** Claude (Claude Code)
- **Prompt:** "Plan the Google Maps integration for the Flutter app" → followed by implementation of the full location feature pipeline
- **Output:** Implemented full feature-first pipeline for location: `HomeMapController` (manages map state + user location), `UserLocation` model, `LocationRepository` (handles permissions + coordinate fetching), `LocationService` (geolocation calls); added `google_maps_flutter` and `geolocator` dependencies to `pubspec.yaml`; configured Android `AndroidManifest.xml` and iOS `Info.plist` with location permissions; registered `GeolocatorPlugin` in platform-specific files; updated `client_home_screen.dart` to display an interactive map widget. 13 files changed, 369 additions.
- **Commit:** [`be02d16`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/be02d16) (branch `mapIntegration`)

#### US09 — Stripe Integration Design Spec
- **Tool:** Claude (Claude Code)
- **Prompt:** "explain to me how u would normally implement stripe to this project tech stack"
- **Output:** Authored a full marketplace payment architecture design spec: `flutter_stripe` + 5 Supabase Edge Functions (`create-setup-intent`, `create-connect-account`, `create-payment-intent`, `capture-payment-intent`, `stripe-webhook`); Stripe Connect Express for pro payouts; authorise-then-capture model (`capture_method: "manual"`) with a single `PaymentIntent` per job; `SetupIntent` card collection at request screen step 4; hold authorised on submit, capture on pro "Mark Complete"; `payments` table schema with `authorised | captured | cancelled | refunded` status and `amount_authorised`/`amount_charged` split; `payment_methods` table populated by `setup_intent.succeeded` webhook. Saved as `docs/superpowers/specs/2026-05-11-stripe-integration-design.md`.
- **Commit:** [`0b4a000`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/0b4a000)

#### US08 — Review Submission Enhancement & RLS Policies
- **Tool:** Claude (Claude Code)
- **Prompt:** "Add RLS policies for job detail reviews" → followed by enhancing the review submission process with error handling and validation
- **Output:** Enhanced `JobDetailController` with review submission error handling and input validation; updated `ReviewCard` widget and `JobDetailActionBar` for proper review flow; added/verified RLS policies on the reviews table for secure read/write access; fixed status string mismatch (`on_the_way` → `on_my_way`) in tests; updated `job_detail_controller_test.dart`.
- **Commit:** [`0835d6b`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/0835d6b), [`e06cc1b`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/e06cc1b) (branch `reviewimplement`, merged via [PR #57](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/pull/57))

#### Merge Conflict Resolution & Test Maintenance
- **Tool:** Claude (Claude Code)
- **Prompt:** "Fix the unresolved merge conflicts and clean up stale test parameters"
- **Output:** Removed leftover conflict markers from `test_bundle.dart` (smoke_test reference from origin/main side had no matching import); dropped unused `uploadedPath` param from `_FakeProfileRepository` in `profile_controller_test.dart` to clear `unused_element_parameter` lint; reordered test imports and groups for consistency across the test suite.
- **Commit:** [`d15242c`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/d15242c), [`5c9f805`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/5c9f805)

#### Architecture Audit — Feature Pipeline Violations
- **Tool:** Claude (Claude Code)
- **Prompt:** "analyze every feature and create a list of every instance where that feature pipeline is broken, basically anything out of place. A screen calling a db, or something that shouldn't be where it is"
- **Output:** Systematic audit of all 56 `.dart` files across 10 feature modules, identifying 30 architectural violations in 8 categories: 3 direct Supabase calls remaining in presentation layer, 2 features missing pipeline layers entirely, 7 cross-feature coupling issues (e.g., 4 features importing `auth_shared.dart` from the auth feature), 7 instances of business logic in widgets (status mapping, cost calculation, timeline state machine), 5 services doing repository-level work (JSON→model mapping), 4 repositories acting as thin passthroughs, 7 repositories importing `supabase_flutter` types directly, and 1 missing model (`user_model.dart` still a TODO). Produced a prioritised fix list.
- **Commit:** *(no commit — analysis only)*



---

### Sprint 3

---

#### US08 — Stripe Connect onboarding in Pro profile
- **Tool:** Claude (Claude Code)
- **Prompt:** "wire up the pro profile screen so a professional can connect their Stripe account from the app and see the connection status"
- **Output:** Extended `ProProfileController` with Stripe Connect onboarding state and a `startStripeOnboarding` action that hits the `create-connect-account` Edge Function and opens the returned URL; added `stripeAccountId`/`stripeOnboardingComplete` fields to `ProProfileModel`; updated `ProProfileService`/`ProProfileRepository` to fetch and persist account status; added a "Payments" section to `pro_profile_screen.dart` with a connect-account CTA and a "Connected" badge once onboarding completes. Added `flutter_stripe` and `url_launcher` to `pubspec.yaml`.
- **Commit:** [`56bdbb0`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/56bdbb0) (merged via [PR #58](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/pull/58))

#### US13 — Work settings & availability scheduling
- **Tool:** Claude (Claude Code)
- **Prompt:** "build the work settings feature so pros can set their weekly availability and upload credential docs, follow the same controller/repository/service layering as the rest of the app"
- **Output:** New `pro/work_settings/` feature pipeline: `AvailabilityScheduleModel` (per-weekday open/close + breaks, JSON round-trip), `WorkSettingsService` (Supabase read/write + Storage upload for credentials), `WorkSettingsRepository` (wraps service errors as `WorkSettingsFailure`), and `WorkSettingsController` exposing schedule edits, credential upload, and persist actions. Made `scheduledAt` optional on requests so pros without a fixed schedule still receive jobs; added 762-line test suite (`work_settings_controller_test.dart`, `availability_schedule_model_test.dart`, `work_settings_repository_test.dart`).
- **Commit:** [`2786b70`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/2786b70), [`e1d247e`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/e1d247e), [`4be6ae2`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/4be6ae2) (branch `US13`, merged via [PR #61](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/pull/61))

#### US09 — Stripe payments end-to-end (authorise → capture)
- **Tool:** Claude (Claude Code)
- **Prompt:** "implement the stripe payment design spec we wrote in sprint 2 — card on file at request submit, authorise on submit, capture when the pro marks complete"
- **Output:** Created `features/payments/` feature with `PaymentService` (calls `create-payment-intent`, `capture-payment-intent`, lists saved cards), `PaymentRepository`, `PaymentMethodsController`, `PaymentMethodsScreen`, and `PaymentModels`. Wired the request flow: `RequestController.submit` now blocks unless a card is on file and authorises the PaymentIntent; `JobDetailController` fetches payment info and captures on completion; `PaymentSummaryCard` shows authorised/captured amounts on the job detail screen. Configured Android `MainActivity` → `FlutterFragmentActivity` and switched themes to AppCompat/MaterialComponents so `PaymentSheet` renders. Added `core/stripe/stripe_config.dart` and ProGuard rules for push provisioning.
- **Commit:** [`5b2e368`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/5b2e368), [`28a9375`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/28a9375) (branch `payments`, merged via [PR #62](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/pull/62))

#### US09 — Supabase Edge Functions for Stripe
- **Tool:** Claude (Claude Code)
- **Prompt:** "now write the edge functions: create-setup-intent, create-connect-account, create-payment-intent, capture-payment-intent, stripe-webhook — share auth/cors helpers"
- **Output:** Added 5 Deno Edge Functions under `supabase/functions/` plus shared helpers (`_shared/auth.ts`, `_shared/cors.ts`, `_shared/responses.ts`, `_shared/stripe.ts`, `_shared/supabase.ts`). `create-setup-intent` lazily creates the Stripe customer; `stripe-webhook` handles `setup_intent.succeeded` (upsert into `payment_methods`) and `payment_intent.*` events (update `payments.status` + `amount_charged`). Backed by request_controller test additions covering both "has card" and "no card" submission paths.
- **Commit:** [`d62bbd5`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/d62bbd5)

#### Pro Dashboard
- **Tool:** Claude (Claude Code)
- **Prompt:** "design and build a pro dashboard — stats on active jobs, monthly earnings, average rating — same feature layering as the rest" (spec written first, then implementation)
- **Output:** Wrote `docs/superpowers/specs/2026-05-26-pro-dashboard-design.md` then implemented `pro/home/` feature: `ProDashboardStats` model, `ProDashboardService` (aggregates from `service_requests`, `payments`, `reviews`), `ProDashboardRepository`, `ProDashboardController`, and `ProDashboardView` widget shown on `pro_home_screen.dart`. Added `pro_dashboard_controller_test.dart` and `pro_dashboard_view_test.dart`.
- **Commit:** [`dbe4e2f`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/dbe4e2f) (branch `pro-dashboard`, merged via [PR #63](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/pull/63))

#### US15 — Google Maps integration plan & location picker
- **Tool:** Claude (Claude Code)
- **Prompt:** "plan the full google maps integration — picker for request address, static map preview on job detail, lat/lng on professional_profiles, postgis migration" → then "now implement it"
- **Output:** Wrote `docs/superpowers/plans/2026-05-27-google-maps-integration.md` (1047 lines) and corresponding design doc. Implemented: PostGIS migration `20260527000000_add_location_coords.sql` adding `latitude`/`longitude` to `service_requests` and `professional_profiles`; new `shared/location/` feature with `LocationService`, `PickedLocation` model, `LocationPickerScreen` (interactive map + reverse geocoding), and `StaticMapView` widget; updated `JobDetailModel` to parse coords and render a static map; updated `RequestScreen` step 2 to use the picker; registered the geolocator plugin on Windows/macOS. Added `location_picker_screen` tests, `picked_location_test.dart`, `fake_location_service.dart`, and `job_detail_location_test.dart`.
- **Commit:** [`d62bbd5`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/d62bbd5), [`a2493ad`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/a2493ad), [`befa69e`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/befa69e) (branch `maps`, merged via [PR #65](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/pull/65))

#### Client home redesign — trade tiles & deep-link to request
- **Tool:** Claude (Claude Code)
- **Prompt:** "redesign the client home — instead of a giant request button, show a grid of trade tiles, tapping a tile opens the request screen pre-selected on that trade"
- **Output:** Wrote `docs/superpowers/specs/2026-05-27-client-home-request-entry-design.md`. Rewrote `client_home_screen.dart` (-410/+140 lines) into a trade-tile grid backed by the existing `TradesRepository`/`TradeIconMapper`; added a `preselectedTradeSlug` parameter to `RequestScreen` that skips step 1 when set; threaded the deep-link from tile tap. Added `client_home_tiles_test.dart` and request-screen tests for the preselection path.
- **Commit:** [`528166b`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/528166b), [`a2493ad`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/a2493ad)

#### Polish — job ordering, reviews truncation, CI timeouts
- **Tool:** Claude (Claude Code)
- **Prompt:** "newest jobs first in history" / "only show first 3 reviews with a 'see more' toggle" / "android+web ci jobs are hanging, add a timeout"
- **Output:** Flipped `ProJobsService` and history queries to descending `created_at`; added `maxVisible` parameter to the reviews section on `job_detail_screen.dart` with an expand/collapse toggle; added `timeout-minutes` to the Android and Web build jobs in the GitHub Actions workflow.
- **Commit:** [`be02e89`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/be2e089), [`036d97b`](https://github.com/LEIC-ES-2025-26-2LEIC02/T1/commit/036d97b)
