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
    final addr = await widget.locationService
        .addressFor(_center.latitude, _center.longitude);
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
        const SnackBar(
          content: Text('Location unavailable. Move the pin manually.'),
        ),
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
