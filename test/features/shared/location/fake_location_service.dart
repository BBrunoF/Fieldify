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
