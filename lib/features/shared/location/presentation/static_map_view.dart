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
