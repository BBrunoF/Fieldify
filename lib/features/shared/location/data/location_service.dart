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
