# Development Environment Setup

This guide walks through everything needed to clone Fieldify, run it locally on an emulator or physical device, and execute the test suite.

---

## 1. Prerequisites

### Required tools

| Tool | Version | Notes |
|------|---------|-------|
| Flutter SDK | `3.11.0` or newer | Dart SDK ships with Flutter — no separate install |
| Git | any recent | for cloning |
| Android Studio | latest stable | provides the Android SDK, emulator, and platform tools |
| Xcode | latest stable (macOS only) | required for iOS builds |
| VS Code or Android Studio | either | Flutter/Dart extensions recommended |

Verify your install:

```bash
flutter --version
flutter doctor
```

`flutter doctor` must report no issues for the platforms you intend to target (Android, iOS, or both).

### Platform SDKs

- **Android:** Android SDK Platform 34+, Android SDK Build-Tools 34+, at least one system image (Pixel 6 API 34 is a good default).
- **iOS** (macOS only): Xcode Command Line Tools (`xcode-select --install`) and CocoaPods (`sudo gem install cocoapods`).

---

## 2. Clone & install dependencies

```bash
git clone https://github.com/LEIC-ES-2025-26-2LEIC02/T1.git
cd T1
flutter pub get
```

On iOS, also run:

```bash
cd ios && pod install && cd ..
```

---

## 3. Credentials & environment variables

### Google Maps (`.env`)

The Google Maps SDK key lives in a gitignored `.env` at the repo root. Copy the example and fill in your key:

```bash
cp .env.example .env
```

Then edit `.env`:

```dotenv
MAPS_API_KEY=AIza...   # Google Maps SDK key — Maps SDK for Android + iOS enabled, key restricted
```

**How it's consumed:**

- **Android** — [`android/app/build.gradle.kts`](../android/app/build.gradle.kts) reads `MAPS_API_KEY` from `.env` at configure time (falling back to the `MAPS_API_KEY` environment variable for CI) and injects it into [`AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml) via `manifestPlaceholders`.
- **iOS** — Copy `ios/Flutter/Secrets.xcconfig.example` to `ios/Flutter/Secrets.xcconfig` (also gitignored) and put the same `MAPS_API_KEY=...` line there. `Debug.xcconfig`/`Release.xcconfig` `#include?` it, `Info.plist` reads `$(MAPS_API_KEY)`, and `AppDelegate.swift` passes it to `GMSServices.provideAPIKey(...)` at launch.

Keep the iOS and root values in sync. Without a key, the app still launches but Google Maps tiles render blank.

**Getting a key:** Google Cloud Console → APIs & Services → enable "Maps SDK for Android" and "Maps SDK for iOS" → Credentials → Create API key → restrict to your Android package name (`com.example.project`) + SHA-1 fingerprint and your iOS bundle ID.

### Firebase (`google-services.json`)

`android/app/google-services.json` is gitignored. Copy the example and fill in your Firebase project values:

```bash
cp android/app/google-services.json.example android/app/google-services.json
```

Edit `google-services.json` with your Firebase project's `project_number`, `project_id`, `mobilesdk_app_id`, and Android API key. These are available in the Firebase console under **Project Settings → Your apps → Android app → google-services.json** (download the real file from there). Contact the team if you need the values for the shared project.

### Supabase

`lib/core/supabase/supabase_client.dart` contains two placeholder values that you must fill in before the app can reach the backend:

```dart
const supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
```

To run against the project's Supabase instance, contact the team for the real URL and anon key.

To run against your own Supabase project:

1. Create a project at [supabase.com](https://supabase.com).
2. In the Supabase SQL Editor, run `supabase/migrations/20260616000000_initial_schema.sql` — this creates all tables, triggers, the `pro_ratings` view, and enables PostGIS.
3. Run `supabase/seed.sql` to populate the `trades` table and read the storage bucket / test account instructions.
4. Update `supabaseUrl` and `supabaseAnonKey` in `lib/core/supabase/supabase_client.dart`.
5. Add RLS policies for every table (see Supabase dashboard → Authentication → Policies). Without policies, all queries are denied by default.
6. Create storage buckets (`service-request-photos`, `credential-documents`, `avatars`) — instructions are in `seed.sql`.
7. Deploy the Edge Functions under `supabase/functions/` (`create-setup-intent`, `create-connect-account`, `create-payment-intent`, `capture-payment-intent`, `stripe-webhook`, `send-push-notification`) and set their secrets (`STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, etc.) in the Supabase dashboard.

### Test accounts

Shared dev credentials used by Patrol tests and manual QA:

| Role | Email | Password |
|------|-------|----------|
| Client | `client@client.com` | `clientclient` |
| Professional | *currently only creatable via direct DB edit — see Bug Tracking #1* | — |

---

## 4. Running the app

### Android emulator

```bash
flutter emulators --launch <emulator_id>    # or start one from Android Studio
flutter run
```

### iOS simulator (macOS only)

```bash
open -a Simulator
flutter run
```

### Physical device

Enable USB debugging (Android) or trust the development certificate (iOS), connect via USB, then `flutter run`.

---

## 5. Platform permissions

These are already declared in the repo — listed here for reference when adding new platform features.

**iOS** — `ios/Runner/Info.plist`:
- `NSCameraUsageDescription` — photo capture in service requests
- `NSPhotoLibraryUsageDescription` — photo picker

**Android** — `android/app/src/main/AndroidManifest.xml`:
- `CAMERA`
- `READ_MEDIA_IMAGES` (Android 13+) / `READ_EXTERNAL_STORAGE` (older)

---

## 6. Testing

### Unit & widget tests

```bash
flutter test
```

Target a single file:

```bash
flutter test test/features/shared/job_detail/controllers/job_detail_controller_test.dart
```

Target a single test by name:

```bash
flutter test --plain-name "populates detail on success"
```

### Patrol UATs (integration tests)

Patrol drives a real app on an emulator or device — ensure one is running first.

```bash
patrol test
```

Target a single suite:

```bash
patrol test --target patrol_test/job_detail_test.dart
```

Target a single scenario:

```bash
patrol test --target patrol_test/job_detail_test.dart -n "client cancels a pending job from the detail screen"
```

**If the emulator fails with `INSTALL_FAILED_INSUFFICIENT_STORAGE`:** wipe data on the AVD (Android Studio → Device Manager → Wipe Data), cold-boot, or resize the emulator storage.

**If you get a stale-kernel error after pulling:** run `flutter clean && flutter pub get`.

---

## 7. Linting & analysis

```bash
flutter analyze
```

The project follows the default `flutter_lints` ruleset (see `analysis_options.yaml`). CI is not yet wired — run `flutter analyze` locally before opening a PR.

---

## 8. Project structure

```
lib/
  core/               # cross-cutting: theme, routing, Supabase client
  features/
    auth/             # login, registration
    client/           # client-only features (home, request, job_history)
    pro/              # professional-only features (incoming_jobs)
    shared/           # shared features (job_detail)
    home/             # shared shell/bottom nav
  shared/widgets/     # reusable UI primitives

test/                 # mirrors lib/ structure — unit + widget tests
patrol_test/          # integration (UAT) tests

docs/                 # architecture decisions, domain model, UML, project mgmt
```

Each feature follows a **Screen → Controller → Repository → Service** layering with `ChangeNotifier`-based controllers. See `docs/architecture.md` for technology decisions and `docs/fieldify-logical-architecture-description.md` for the layer contracts.

---

## 9. Common pitfalls

- **`flutter pub get` fails** → check `flutter --version` matches the `environment.sdk` bound in `pubspec.yaml`.
- **Supabase calls return empty results** → almost always an RLS policy on the table being queried. Check the Supabase dashboard → table → Policies.
- **Patrol test discovers 0 tests** → the generated `patrol_test/test_bundle.dart` is stale. Run `flutter clean` and try again; Patrol regenerates it on the next run.
- **iOS build fails on `pod install`** → delete `ios/Podfile.lock` and `ios/Pods/`, then re-run.

---
