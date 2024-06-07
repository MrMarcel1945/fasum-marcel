import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationPicker extends StatefulWidget {
  @override
  _LocationPickerState createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  GoogleMapController? _controller;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
    _controller?.moveCamera(CameraUpdate.newLatLng(_currentLocation!));
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      _currentLocation = location;
    });
  }

  void _confirmLocation() {
    if (_currentLocation != null) {
      Navigator.pop(context, _currentLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Lokasi'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _confirmLocation,
          ),
        ],
      ),
      body: _currentLocation == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLocation!,
          zoom: 15,
        ),
        onMapCreated: (controller) {
          _controller = controller;
        },
        onTap: _onMapTapped,
        markers: _currentLocation != null
            ? {
          Marker(
            markerId: MarkerId('currentLocation'),
            position: _currentLocation!,
          ),
        }
            : {},
      ),
    );
  }
}
