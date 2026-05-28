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
