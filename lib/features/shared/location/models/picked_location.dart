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
