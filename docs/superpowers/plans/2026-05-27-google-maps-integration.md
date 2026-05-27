# Google Maps Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the app's fake/placeholder maps with real Google Maps and let users pick real locations via an interactive map pin + "use my location", reverse-geocoding the address.

**Architecture:** A new shared `location` module exposes a mockable `LocationService` (geolocator + geocoding), a reusable full-screen `LocationPickerScreen` (returns `PickedLocation`), and a read-only `StaticMapView`. Four existing screens consume them. PostGIS coordinates become readable via generated `lat`/`lng` columns. Existing `POINT` writes are unchanged.

**Tech Stack:** Flutter, `google_maps_flutter`, `geolocator`, `geocoding`, Supabase (PostGIS), ChangeNotifier state.

---

## File Structure

**Create:**
- `lib/core/location/location_constants.dart` — shared default center (Porto).
- `lib/features/shared/location/models/picked_location.dart` — `PickedLocation` value type.
- `lib/features/shared/location/data/location_service.dart` — `LocationService` interface + `GeolocatorLocationService` impl.
- `lib/features/shared/location/presentation/static_map_view.dart` — read-only map widget.
- `lib/features/shared/location/presentation/location_picker_screen.dart` — interactive picker.
- `supabase/migrations/20260527000000_add_location_coords.sql` — generated lat/lng columns.
- `test/features/shared/location/picked_location_test.dart`
- `test/features/shared/location/fake_location_service.dart` — shared test double.

**Modify:**
- `pubspec.yaml` — add 3 deps.
- `lib/features/client/request/controllers/request_controller.dart` — `submit` takes lat/lng.
- `lib/features/client/request/presentation/screens/request_screen.dart` — wire picker into Step 3.
- `lib/features/shared/job_detail/data/models/job_detail_model.dart` — parse lat/lng.
- `lib/features/shared/job_detail/presentation/screens/job_detail_screen.dart` — use `StaticMapView`.
- `lib/features/pro/profile/data/services/work_settings_service.dart` — add `fetchLocation`.
- `lib/features/pro/profile/data/repositories/work_settings_repository.dart` — expose `fetchLocation`.
- `lib/features/pro/profile/controllers/work_settings_controller.dart` — load + hold location.
- `lib/features/pro/profile/presentation/screens/pro_profile_screen.dart` — picker replaces manual lat/lng entry.
- `lib/features/client/home/presentation/screens/client_home_screen.dart` — `StaticMapView` in `_buildMap`.
- `test/features/client/request/controllers/request_controller_test.dart` — pass lat/lng.

---

## Task 1: Add dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the three packages**

Run (lets pub resolve versions compatible with the project SDK):

```bash
flutter pub add google_maps_flutter geolocator geocoding
```

- [ ] **Step 2: Verify they resolved**

Run: `flutter pub get`
Expected: exits 0; `pubspec.yaml` now lists `google_maps_flutter`, `geolocator`, `geocoding` under `dependencies`.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "build: add google_maps_flutter, geolocator, geocoding"
```

---

## Task 2: PostGIS generated coordinate columns

The `location` (service_requests) and `base_location` (professional_profiles) geography columns are write-only today. Add generated `lat`/`lng` columns so they can be selected as plain floats. `job_detail_service` selects `*`, so it picks these up automatically.

**Files:**
- Create: `supabase/migrations/20260527000000_add_location_coords.sql`

- [ ] **Step 1: Write the migration**

```sql
-- Expose PostGIS point coordinates as plain selectable floats.
-- ST_X = longitude, ST_Y = latitude. NULL location -> NULL coords.

alter table public.service_requests
  add column if not exists lat double precision
    generated always as (st_y(location::geometry)) stored,
  add column if not exists lng double precision
    generated always as (st_x(location::geometry)) stored;

alter table public.professional_profiles
  add column if not exists lat double precision
    generated always as (st_y(base_location::geometry)) stored,
  add column if not exists lng double precision
    generated always as (st_x(base_location::geometry)) stored;
```

- [ ] **Step 2: Apply the migration**

Run: `supabase db push`
Expected: migration applies without error. (If using a local stack: `supabase migration up`.)

- [ ] **Step 3: Verify columns exist**

Run:
```bash
supabase db execute "select column_name from information_schema.columns where table_name='service_requests' and column_name in ('lat','lng');"
```
Expected: two rows — `lat`, `lng`.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260527000000_add_location_coords.sql
git commit -m "feat(db): add generated lat/lng columns for request and pro location"
```

---

## Task 3: Shared constants + PickedLocation model

**Files:**
- Create: `lib/core/location/location_constants.dart`
- Create: `lib/features/shared/location/models/picked_location.dart`
- Test: `test/features/shared/location/picked_location_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/shared/location/models/picked_location.dart';

void main() {
  test('PickedLocation holds coordinates and address', () {
    const p = PickedLocation(lat: 41.1579, lng: -8.6291, address: 'Porto');
    expect(p.lat, 41.1579);
    expect(p.lng, -8.6291);
    expect(p.address, 'Porto');
  });

  test('equality is value-based', () {
    const a = PickedLocation(lat: 1, lng: 2, address: 'x');
    const b = PickedLocation(lat: 1, lng: 2, address: 'x');
    expect(a, equals(b));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/shared/location/picked_location_test.dart`
Expected: FAIL — `picked_location.dart` does not exist.

- [ ] **Step 3: Write the model**

`lib/features/shared/location/models/picked_location.dart`:

```dart
class PickedLocation {
  final double lat;
  final double lng;
  final String address;

  const PickedLocation({
    required this.lat,
    required this.lng,
    required this.address,
  });

  @override
  bool operator ==(Object other) =>
      other is PickedLocation &&
      other.lat == lat &&
      other.lng == lng &&
      other.address == address;

  @override
  int get hashCode => Object.hash(lat, lng, address);
}
```

- [ ] **Step 4: Write the constants**

`lib/core/location/location_constants.dart`:

```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Fallback map center (Porto) used when the device location is unavailable.
const LatLng kDefaultLocation = LatLng(41.1579, -8.6291);
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/shared/location/picked_location_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/location/location_constants.dart lib/features/shared/location/models/picked_location.dart test/features/shared/location/picked_location_test.dart
git commit -m "feat(location): add PickedLocation model and default center constant"
```

---

## Task 4: LocationService (interface + impl + fake)

**Files:**
- Create: `lib/features/shared/location/data/location_service.dart`
- Create: `test/features/shared/location/fake_location_service.dart`

- [ ] **Step 1: Write the interface + implementation**

`lib/features/shared/location/data/location_service.dart`:

```dart
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Device geolocation + reverse geocoding. Defined as an interface so tests
/// can inject a fake (geolocator/geocoding hit platform channels).
abstract class LocationService {
  /// Current device position, or null if permission is denied/unavailable.
  Future<LatLng?> currentPosition();

  /// Human-readable address for a coordinate, or null on failure.
  Future<String?> addressFor(double lat, double lng);
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<LatLng?> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      final pos = await Geolocator.getCurrentPosition();
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> addressFor(double lat, double lng) async {
    try {
      final marks = await placemarkFromCoordinates(lat, lng);
      if (marks.isEmpty) return null;
      final m = marks.first;
      final parts = <String?>[
        m.street,
        m.locality,
        m.postalCode,
      ].where((s) => s != null && s.isNotEmpty).toList();
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }
}
```

- [ ] **Step 2: Write the shared fake for tests**

`test/features/shared/location/fake_location_service.dart`:

```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project/features/shared/location/data/location_service.dart';

class FakeLocationService implements LocationService {
  FakeLocationService({this.position, this.address = 'Fake Street, Porto'});

  final LatLng? position;
  final String? address;

  @override
  Future<LatLng?> currentPosition() async => position;

  @override
  Future<String?> addressFor(double lat, double lng) async => address;
}
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/features/shared/location/data/location_service.dart`
Expected: No issues (warnings about unused import are failures — fix them).

- [ ] **Step 4: Commit**

```bash
git add lib/features/shared/location/data/location_service.dart test/features/shared/location/fake_location_service.dart
git commit -m "feat(location): add LocationService interface, geolocator impl, test fake"
```

---

## Task 5: StaticMapView widget

Read-only map with a single marker; gestures disabled. Used by job detail and client home.

**Files:**
- Create: `lib/features/shared/location/presentation/static_map_view.dart`

- [ ] **Step 1: Write the widget**

```dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StaticMapView extends StatelessWidget {
  final LatLng position;
  final double height;
  final double zoom;

  const StaticMapView({
    super.key,
    required this.position,
    this.height = 160,
    this.zoom = 15,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: position, zoom: zoom),
        markers: {
          Marker(markerId: const MarkerId('location'), position: position),
        },
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
        scrollGesturesEnabled: false,
        zoomGesturesEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        liteModeEnabled: true, // Android: lightweight static bitmap.
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/features/shared/location/presentation/static_map_view.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/shared/location/presentation/static_map_view.dart
git commit -m "feat(location): add read-only StaticMapView widget"
```

---

## Task 6: LocationPickerScreen

Full-screen interactive picker. A fixed center pin overlays the map; the map moves under it. "Use my location" recenters. The address is reverse-geocoded when the camera settles. Confirm pops a `PickedLocation`; cancel pops null.

**Files:**
- Create: `lib/features/shared/location/presentation/location_picker_screen.dart`

- [ ] **Step 1: Write the widget**

```dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/location/location_constants.dart';
import '../data/location_service.dart';
import '../models/picked_location.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initial;
  final LocationService locationService;

  const LocationPickerScreen({
    super.key,
    required this.locationService,
    this.initial,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _controller;
  late LatLng _center;
  String _address = '';
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _center = widget.initial ?? kDefaultLocation;
    _resolveAddress();
  }

  Future<void> _resolveAddress() async {
    setState(() => _resolving = true);
    final addr =
        await widget.locationService.addressFor(_center.latitude, _center.longitude);
    if (!mounted) return;
    setState(() {
      if (addr != null) _address = addr;
      _resolving = false;
    });
  }

  Future<void> _useMyLocation() async {
    final pos = await widget.locationService.currentPosition();
    if (pos == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location unavailable. Move the pin manually.')),
      );
      return;
    }
    _center = pos;
    await _controller?.animateCamera(CameraUpdate.newLatLng(pos));
    await _resolveAddress();
  }

  void _confirm() {
    Navigator.of(context).pop(
      PickedLocation(
        lat: _center.latitude,
        lng: _center.longitude,
        address: _address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose location')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            onMapCreated: (c) => _controller = c,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onCameraMove: (pos) => _center = pos.target,
            onCameraIdle: _resolveAddress,
          ),
          const IgnorePointer(
            child: Icon(Icons.location_on, size: 44, color: Colors.red),
          ),
          Positioned(
            right: 16,
            bottom: 120,
            child: FloatingActionButton(
              key: const Key('useMyLocationButton'),
              onPressed: _useMyLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: Text(_resolving ? 'Locating…' : _address),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  key: const Key('confirmLocationButton'),
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Confirm location'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/features/shared/location/presentation/location_picker_screen.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/shared/location/presentation/location_picker_screen.dart
git commit -m "feat(location): add interactive LocationPickerScreen"
```

---

## Task 7: RequestController.submit takes coordinates

Remove the hardcoded Porto constants; accept `latitude`/`longitude` and build the POINT from them.

**Files:**
- Modify: `lib/features/client/request/controllers/request_controller.dart:65-101,114-124`
- Test: `test/features/client/request/controllers/request_controller_test.dart`

- [ ] **Step 1: Update the existing test to pass coordinates and assert the POINT**

In `request_controller_test.dart`, in the "submits the payload then authorises the card" test, add `latitude`/`longitude` args to the `submit(...)` call:

```dart
      await controller.submit(
        tradeId: 4,
        title: 'Broken AC',
        description: 'The unit stopped cooling.',
        addressText: 'Rua das Flores 10',
        latitude: 41.1579,
        longitude: -8.6291,
        scheduledAt: scheduledAt,
      );
```

The existing `expect(submittedData, {...})` already asserts `'location': 'POINT(-8.6291 41.1579)'`, so it stays correct. Add `latitude`/`longitude` to the other two `submit(...)` calls in the file as well (use `latitude: 41.1579, longitude: -8.6291`).

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/client/request/controllers/request_controller_test.dart`
Expected: FAIL — `submit` has no named parameter `latitude`.

- [ ] **Step 3: Update the controller signature and body**

In `request_controller.dart`, change the `submit` signature to add the two required params after `addressText`:

```dart
  Future<void> submit({
    required int tradeId,
    required String title,
    required String description,
    required String addressText,
    required double latitude,
    required double longitude,
    required DateTime? scheduledAt,
    List<File> photos = const [],
  }) async {
```

Delete the hardcoded block:

```dart
    // Hardcoded Porto coords until Google Maps geocoding is wired up
    const lat = 41.1579;
    const lng = -8.6291;
```

Change the payload line to use the params:

```dart
        'location': 'POINT($longitude $latitude)',
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/client/request/controllers/request_controller_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/client/request/controllers/request_controller.dart test/features/client/request/controllers/request_controller_test.dart
git commit -m "feat(request): pass real coordinates into submit"
```

---

## Task 8: Wire picker into Request Step 3

Replace the fake `MapPainter`/`MapPin` block with a tappable preview that opens `LocationPickerScreen`, and feed the result into `_addressCtrl` + `_submitRequest`.

**Files:**
- Modify: `lib/features/client/request/presentation/screens/request_screen.dart` (state fields ~line 44-46, `_submitRequest` ~118-140, `_buildStep3` map block ~699-735)

- [ ] **Step 1: Add picker imports and state fields**

At the top imports of `request_screen.dart`, add:

```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../shared/location/data/location_service.dart';
import '../../../../shared/location/presentation/location_picker_screen.dart';
import '../../../../shared/location/models/picked_location.dart';
import '../../../../../core/location/location_constants.dart';
```

Near the other state fields (around the `_addressCtrl` declaration, line 46), add:

```dart
  final LocationService _locationService = GeolocatorLocationService();
  LatLng _pickedLatLng = kDefaultLocation;
```

- [ ] **Step 2: Add the picker open method**

Add this method to the State class (next to `_submitRequest`):

```dart
  Future<void> _openLocationPicker() async {
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          locationService: _locationService,
          initial: _pickedLatLng,
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      _pickedLatLng = LatLng(result.lat, result.lng);
      if (result.address.isNotEmpty) _addressCtrl.text = result.address;
    });
  }
```

- [ ] **Step 3: Pass coordinates from `_submitRequest`**

In `_submitRequest`, update the `submit(...)` call to include:

```dart
    await _requestCtrl.submit(
      tradeId: trades[_cat].id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      addressText: _addressCtrl.text.trim(),
      latitude: _pickedLatLng.latitude,
      longitude: _pickedLatLng.longitude,
      scheduledAt: scheduledAt,
      photos: _photos,
    );
```

- [ ] **Step 4: Replace the fake map block in `_buildStep3`**

Replace the `ClipRRect(... CustomPaint(painter: MapPainter ...) ...)` block (lines ~699-735) with a tappable static preview:

```dart
        GestureDetector(
          key: const Key('requestMapPreview'),
          onTap: _openLocationPicker,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: StaticMapView(position: _pickedLatLng, height: 120),
          ),
        ),
```

Add the import:

```dart
import '../../../../shared/location/presentation/static_map_view.dart';
```

- [ ] **Step 5: Verify it analyzes and the request test still passes**

Run: `flutter analyze lib/features/client/request/presentation/screens/request_screen.dart`
Expected: No issues (remove any now-unused `MapPainter`/`MapPin` imports it flags).

Run: `flutter test test/features/client/request`
Expected: PASS. (Widget tests don't render the platform map; the preview is a child widget. If a widget test taps the old fake map, update its key to `requestMapPreview`.)

- [ ] **Step 6: Commit**

```bash
git add lib/features/client/request/presentation/screens/request_screen.dart
git commit -m "feat(request): open Google Maps location picker in step 3"
```

---

## Task 9: Job detail static map

Parse `lat`/`lng` from the job row and render `StaticMapView` instead of the `MapMiniCard` placeholder.

**Files:**
- Modify: `lib/features/shared/job_detail/data/models/job_detail_model.dart:195-260`
- Modify: `lib/features/shared/job_detail/presentation/screens/job_detail_screen.dart:157`
- Test: `test/features/shared/job_detail/...` (add a model parse test — create `test/features/shared/job_detail/job_detail_location_test.dart`)

- [ ] **Step 1: Write the failing model test**

`test/features/shared/job_detail/job_detail_location_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/shared/job_detail/data/models/job_detail_model.dart';

void main() {
  test('JobDetail parses lat/lng from the job row', () {
    final job = JobDetail.fromJson(
      jobRow: {
        'id': 'job-1',
        'title': 'Leak',
        'description': 'desc',
        'address_text': 'Rua X',
        'status': 'pending',
        'client_id': 'c-1',
        'pro_id': null,
        'trade_id': 1,
        'lat': 41.1579,
        'lng': -8.6291,
      },
      counterpartyRow: null,
      viewerRole: ViewerRole.client,
      photoUrls: const [],
    );
    expect(job.lat, 41.1579);
    expect(job.lng, -8.6291);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/shared/job_detail/job_detail_location_test.dart`
Expected: FAIL — `JobDetail` has no getter `lat`.

- [ ] **Step 3: Add fields to `JobDetail`**

In `job_detail_model.dart`, add two nullable fields to the `JobDetail` class, the constructor, and `fromJson`:

In the field list (after `addressText`):
```dart
  final double? lat;
  final double? lng;
```
In the constructor (after `required this.addressText,`):
```dart
    required this.lat,
    required this.lng,
```
In `fromJson`'s returned `JobDetail(...)` (after `addressText: ...,`):
```dart
      lat: (jobRow['lat'] as num?)?.toDouble(),
      lng: (jobRow['lng'] as num?)?.toDouble(),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/shared/job_detail/job_detail_location_test.dart`
Expected: PASS.

- [ ] **Step 5: Render the map in the screen**

In `job_detail_screen.dart`, add imports:

```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../location/presentation/static_map_view.dart';
```

Replace line 157 `add(const MapMiniCard(etaLabel: 'ETA coming soon'));` with:

```dart
        if (job.lat != null && job.lng != null) {
          add(ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: StaticMapView(position: LatLng(job.lat!, job.lng!)),
          ));
        } else {
          add(const MapMiniCard(etaLabel: 'Location unavailable'));
        }
```

(Confirm the variable holding the job in that scope is named `job`; adjust if it differs. Keep the `MapMiniCard` import for the fallback branch.)

- [ ] **Step 6: Verify analyze + tests**

Run: `flutter analyze lib/features/shared/job_detail`
Expected: No issues.

Run: `flutter test test/features/shared/job_detail`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/shared/job_detail test/features/shared/job_detail/job_detail_location_test.dart
git commit -m "feat(job-detail): show real map at the job location"
```

> Note: `job_detail_service` already selects `*` from `service_requests`, so the generated `lat`/`lng` columns from Task 2 are returned with no service change needed.

---

## Task 10: Pro profile location picker

Add `fetchLocation` to read the pro's stored point, load it into the controller, and replace the manual lat/lng text fields with a map preview that opens `LocationPickerScreen`.

**Files:**
- Modify: `lib/features/pro/profile/data/services/work_settings_service.dart`
- Modify: `lib/features/pro/profile/data/repositories/work_settings_repository.dart`
- Modify: `lib/features/pro/profile/controllers/work_settings_controller.dart`
- Modify: `lib/features/pro/profile/presentation/screens/pro_profile_screen.dart`

- [ ] **Step 1: Add `fetchLocation` to the service**

In `work_settings_service.dart`, add (mirrors `fetchServiceRadius`):

```dart
  Future<({double lat, double lng})?> fetchLocation() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final row = await supabase
        .from('professional_profiles')
        .select('lat, lng')
        .eq('profile_id', user.id)
        .maybeSingle();

    final lat = (row?['lat'] as num?)?.toDouble();
    final lng = (row?['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return (lat: lat, lng: lng);
  }
```

- [ ] **Step 2: Expose it on the repository**

In `work_settings_repository.dart`, add a method delegating to the service, following the existing `saveLocation` wrapper style:

```dart
  Future<({double lat, double lng})?> fetchLocation() async {
    try {
      return await _service.fetchLocation();
    } catch (_) {
      return null;
    }
  }
```

- [ ] **Step 3: Hold location in the controller**

In `work_settings_controller.dart`, add a nullable field, a getter, and load it where the controller loads other settings (alongside `fetchServiceRadius`). Add:

```dart
  ({double lat, double lng})? _location;
  ({double lat, double lng})? get location => _location;
```

In the existing load method that calls `fetchServiceRadius`, also do:

```dart
    _location = await _repo.fetchLocation();
```

and `notifyListeners()` (the method already notifies). Confirm `setLocation` already updates `_location` after saving; if not, set `_location = (lat: latitude, lng: longitude);` inside `setLocation` before notifying.

- [ ] **Step 4: Replace manual entry UI with the picker**

In `pro_profile_screen.dart`:

Add imports:
```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../shared/location/data/location_service.dart';
import '../../../../shared/location/presentation/location_picker_screen.dart';
import '../../../../shared/location/presentation/static_map_view.dart';
import '../../../../shared/location/models/picked_location.dart';
import '../../../../../core/location/location_constants.dart';
```

Add state fields (near `_latCtrl`/`_lngCtrl`, ~line 71):
```dart
  final LocationService _locationService = GeolocatorLocationService();
  LatLng? _pickedLatLng;
```

Initialize `_pickedLatLng` from the controller's loaded location wherever `_radiusSlider` is initialized from the profile (init + the post-load setState around line 131):
```dart
    final loc = _workController.location;
    if (loc != null) _pickedLatLng = LatLng(loc.lat, loc.lng);
```

Replace `_buildLocationSection()` (lines ~1095-1142, the two `TextFormField`s) with a tappable preview:
```dart
  Widget _buildLocationSection() {
    final center = _pickedLatLng ?? kDefaultLocation;
    return GestureDetector(
      key: const Key('proProfileMapPreview'),
      onTap: _openLocationPicker,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: StaticMapView(position: center, height: 140),
      ),
    );
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          locationService: _locationService,
          initial: _pickedLatLng,
        ),
      ),
    );
    if (result == null) return;
    setState(() => _pickedLatLng = LatLng(result.lat, result.lng));
    _markDirty();
  }
```

Update `_saveLocation()` (lines ~268-279) to use `_pickedLatLng` instead of the text controllers:
```dart
  Future<void> _saveLocation() async {
    final loc = _pickedLatLng;
    if (loc == null) return;
    await _workController.setLocation(
        latitude: loc.latitude, longitude: loc.longitude);
  }
```

Update the save trigger in the main save method (lines ~233-237) — replace the `_latCtrl/_lngCtrl` text checks with:
```dart
    if (_pickedLatLng != null) {
      await _saveLocation();
    }
```

Remove the now-unused `_latCtrl`/`_lngCtrl` declarations (71-72), their `TextEditingController()` inits (99-100), and their `.dispose()` calls (206-207), plus the unused `FilteringTextInputFormatter` import if `flutter analyze` flags it.

- [ ] **Step 5: Verify analyze + existing pro profile test**

Run: `flutter analyze lib/features/pro/profile`
Expected: No issues.

Run: `flutter test test/features/pro/profile/presentation/screens/pro_profile_screen_test.dart`
Expected: PASS. If the existing test interacts with `proProfileLatField`/`proProfileLngField` keys (now removed), update it to tap `proProfileMapPreview` and stub via a fake — or remove those specific assertions, since coordinate entry now happens in the picker (a platform-view screen not exercised in widget tests).

- [ ] **Step 6: Commit**

```bash
git add lib/features/pro/profile test/features/pro/profile
git commit -m "feat(pro-profile): set base location via map picker instead of manual coords"
```

---

## Task 11: Client home map

Replace the fake `_buildMap()` painter with `StaticMapView` centered on the device location (fallback to default center). Keep the "8 pros nearby" / "Porto, Portugal" overlays.

**Files:**
- Modify: `lib/features/client/home/presentation/screens/client_home_screen.dart` (state + `_buildMap` ~240-318)

- [ ] **Step 1: Add imports and location state**

Add imports:
```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../shared/location/data/location_service.dart';
import '../../../../shared/location/presentation/static_map_view.dart';
import '../../../../../core/location/location_constants.dart';
```

Add state fields and load on init (in the State class):
```dart
  final LocationService _locationService = GeolocatorLocationService();
  LatLng _center = kDefaultLocation;
```

In `initState`, after `super.initState()`:
```dart
    _locationService.currentPosition().then((pos) {
      if (pos != null && mounted) setState(() => _center = pos);
    });
```

- [ ] **Step 2: Swap the painter for the map**

In `_buildMap`, replace `Positioned.fill(child: CustomPaint(painter: MapPainter())),` and the `const Center(child: MapPin()),` line with:

```dart
              Positioned.fill(child: StaticMapView(position: _center, height: 160)),
```

Remove the `_ProDot` overlays (they were decorative fake pins) and keep the `Positioned` bottom row with the "Porto, Portugal" pill and "8 pros nearby" pill. Remove now-unused `MapPainter`/`MapPin`/`_ProDot` references if `flutter analyze` flags them.

- [ ] **Step 3: Verify analyze + home tests**

Run: `flutter analyze lib/features/client/home`
Expected: No issues.

Run: `flutter test test`
Expected: PASS (whole suite).

- [ ] **Step 4: Commit**

```bash
git add lib/features/client/home/presentation/screens/client_home_screen.dart
git commit -m "feat(home): show real map centered on the user's location"
```

---

## Task 12: Full verification

- [ ] **Step 1: Analyze the whole project**

Run: `flutter analyze`
Expected: No issues.

- [ ] **Step 2: Run the full unit/widget suite**

Run: `flutter test`
Expected: All pass.

- [ ] **Step 3: Manual smoke test on a device/emulator**

Run: `flutter run`
Verify, with the real API key in place:
- Client home shows a real map centered near you.
- Request → Step 3: tapping the map opens the picker; "Use my location" recenters; the address fills in; submitting stores the picked coordinates.
- Pro profile → Base location: tapping opens the picker; saving persists; reopening shows the saved point.
- Job detail shows the job's location on a real map.

- [ ] **Step 4: Final commit (if any cleanup remained)**

```bash
git add -A
git commit -m "chore: google maps integration cleanup"
```
