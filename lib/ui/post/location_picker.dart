import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  bool _isLocating = false;

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final address = "${place.name}, ${place.locality}";
          if (mounted) Navigator.pop(context, address);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Select Location"),
        backgroundColor: const Color(0xFF0E0E0E),
      ),
      body: Column(
        children: [
          ListTile(
            leading: Icon(Icons.my_location, color: Colors.pink[600]),
            title: Text(_isLocating ? "Locating..." : "Use Current Location", 
                style: const TextStyle(color: Colors.white)),
            onTap: _isLocating ? null : _getCurrentLocation,
          ),
          const Divider(color: Colors.white10),
          // Suggested/Searchable locations
          Expanded(
            child: ListView(
              children: [
                _locationTile("Lekki, Lagos"),
                _locationTile("Ikeja, Lagos"),
                _locationTile("Abuja, Nigeria"),
                _locationTile("Port Harcourt, Nigeria"),
                _locationTile("Benin City, Nigeria"),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _locationTile(String title) {
    return ListTile(
      leading: const Icon(Icons.location_on_outlined, color: Colors.white54),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () => Navigator.pop(context, title),
    );
  }
}