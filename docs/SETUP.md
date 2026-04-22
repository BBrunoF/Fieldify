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

## 3. Backend configuration (Supabase)

The app connects to a hosted Supabase project. Credentials live in `lib/core/supabase/supabase_client.dart`:

```dart
const supabaseUrl = 'https://jdmnvmqkmthjllckzlmp.supabase.co';
const supabaseAnonKey = 'sb_publishable_...';
```

The `anon` key is a public key safe to commit — access is enforced server-side via Row-Level Security policies. No `.env` file is required.

If you want to run against your own Supabase project:

1. Create a project at [supabase.com](https://supabase.com).
2. Apply the schema (tables, triggers, RLS policies) — migration files are not yet tracked in the repo; coordinate with the team for the current SQL dump.
3. Update `supabaseUrl` and `supabaseAnonKey` in `lib/core/supabase/supabase_client.dart`.
4. Create the `service-request-photos` storage bucket (private) with RLS policies scoped to `auth.uid()`.

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
