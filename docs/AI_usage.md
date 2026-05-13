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

#### [PBI ID] - [PBI Name]
- **Tool:** [ferramenta]
- **Prompt:** "[prompt que usaste]"
- **Output:** [breve descrição do que foi gerado]
- **Commit:** [link para o commit]
