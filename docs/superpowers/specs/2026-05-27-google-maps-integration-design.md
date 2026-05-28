# Google Maps Integration — Design

**Date:** 2026-05-27
**Branch:** `maps`

## Goal

Replace the app's fake/placeholder maps with real Google Maps, and let users
pick real locations. The data layer (PostGIS `location` / `base_location`
`POINT` columns) already exists and is written to — this work adds the map UI,
device geolocation, reverse geocoding, and the ability to *read* coordinates
back.

## Scope

In scope:
1. **Request location picker** — Step 3 of the client request flow. Interactive
   map pin + "Use my location", reverse-geocoded address. Replaces the fake
   `MapPainter` and the hardcoded Porto coordinates.
2. **Pro profile location picker** — same picker, lets a pro set their
   `base_location`.
3. **Job detail static map** — replaces the `MapMiniCard` placeholder with a
   real read-only map at the job's location (client & pro).
4. **Client home map** — replaces the fake `_buildMap()` with a read-only map
   centered on the user's current location.

Explicitly out of scope:
- Pro → job route / travel ETA.
- Nearby-pro matching / proximity search. The "X pros nearby" overlay text on
  client home stays static.

## Decisions

- **Geocoding approach:** map pin + current location. Address is
  reverse-geocoded from the pin via the free `geocoding` package. No Google
  Places autocomplete / billing.
- **API key:** already obtained and wired into platform config (placeholders
  swapped). Key must be restricted per-platform in the Cloud console.

## Packages (`pubspec.yaml`)

- `google_maps_flutter` — native map widget (Android/iOS).
- `geolocator` — current position + runtime permission flow.
- `geocoding` — reverse-geocode lat/lng → address string.

## Platform config (DONE)

- **Android** (`android/app/src/main/AndroidManifest.xml`):
  `com.google.android.geo.API_KEY` meta-data; `ACCESS_FINE_LOCATION` +
  `ACCESS_COARSE_LOCATION` permissions. `minSdk = flutter.minSdkVersion` (≥21)
  already satisfies google_maps_flutter.
- **iOS** (`ios/Runner/AppDelegate.swift`): `import GoogleMaps` +
  `GMSServices.provideAPIKey(...)`. (`ios/Runner/Info.plist`):
  `NSLocationWhenInUseUsageDescription`.

## New shared module — `lib/features/shared/location/`

### `LocationService` (+ interface)
Thin wrapper, defined behind an interface so it can be mocked in tests.
- `Future<LatLng?> currentPosition()` — geolocator permission flow +
  `getCurrentPosition`; returns `null` (and the caller falls back) when
  permission is denied or location is unavailable.
- `Future<String?> addressFor(double lat, double lng)` — reverse geocode;
  returns `null` on failure (caller keeps coords, leaves address editable).

### `LocationPickerScreen`
Reusable full-screen picker returning `PickedLocation(lat, lng, address)` via
`Navigator.pop`. Used by **request** and **pro profile**.
- Interactive `GoogleMap`, fixed center pin (the map moves under a static pin).
- "Use my location" button → `currentPosition()` → animates camera.
- Address preview at the bottom, reverse-geocoded as the camera settles.
- Confirm returns the result; Cancel returns `null`.
- Accepts an optional initial `LatLng` (pro's stored location, or a default
  city center).

### `StaticMapView`
Read-only `GoogleMap`, single marker, gestures disabled. Used by **job detail**
and **client home**. Accepts a `LatLng` and an optional marker label.

### `PickedLocation`
Simple value type: `{ double lat; double lng; String address; }`.

## Reading coordinates back from PostGIS (new)

Selecting a geography column returns opaque EWKB. Add a Supabase migration that
exposes coordinates as floats so the app can read existing points — e.g. a view
or RPC returning `ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS
lng`. Decide the exact mechanism (view vs RPC) during planning; prefer whatever
matches existing Supabase usage in the repo.

Then:
- Extend `job_detail_model` to parse `lat`/`lng` for `StaticMapView`.
- Add `WorkSettingsService.fetchLocation()` returning the pro's stored
  `base_location` as lat/lng for the picker's initial pin.

## Integration points

1. **Request Step 3** (`lib/features/client/request/presentation/screens/request_screen.dart`)
   — replace `MapPainter`/`MapPin` block. Tapping the map (or "Change") opens
   `LocationPickerScreen`; result fills `_addressCtrl` and is held as
   selected lat/lng. `submit()` passes real coordinates, removing the hardcoded
   constants in `request_controller.dart` (`lat = 41.1579; lng = -8.6291`).
   Add `latitude`/`longitude` params to `RequestController.submit`.

2. **Pro profile** (`lib/features/pro/profile/...`) — a "Service location" row
   opens `LocationPickerScreen` (initial pin = stored `base_location` or default
   center). Confirm calls the existing
   `WorkSettingsRepository.saveLocation(latitude, longitude)`.

3. **Job detail** (`lib/features/shared/job_detail/presentation/screens/job_detail_screen.dart:157`)
   — replace `MapMiniCard(...)` with `StaticMapView` at the job's location read
   from the model. Keep `MapMiniCard` only if still needed as a loading/empty
   fallback; otherwise remove it.

4. **Client home** (`lib/features/client/home/presentation/screens/client_home_screen.dart:240`)
   — replace `_buildMap()`'s `MapPainter`/`MapPin` with `StaticMapView`
   centered on `currentPosition()` (fallback to default center). Keep the
   "X pros nearby" overlay as static text.

## Error handling

- Location permission denied / unavailable → fall back to a default city center
  (Porto, 41.1579 / -8.6291) and surface a non-blocking hint. Address remains
  manually editable.
- Reverse-geocode failure → keep the coordinates, leave the address field
  editable; do not block confirm.

## Testing

- `GoogleMap` is a platform view and will not render in widget tests.
- Mock `LocationService` (interface) in unit/widget tests.
- Unit-test: POINT/coordinate parsing (`job_detail_model`, work settings),
  and `RequestController.submit` passing the selected coordinates.
- Guard the map widgets so existing Patrol/widget tests for request and
  job detail still pass — inject a fake/placeholder map under test rather than
  the real platform view.

## Default location constant

Porto city center `LatLng(41.1579, -8.6291)` — reuse the value currently
hardcoded in `request_controller.dart` as the shared fallback.
