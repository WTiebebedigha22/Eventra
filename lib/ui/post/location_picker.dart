import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  bool _isLocating = false;
  final TextEditingController _searchController = TextEditingController();

  // --- Theme Colors ---
  static const Color primaryColor = Color(0xFF3E5992);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Colors.black54;

  Future<void> _getCurrentLocation() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLocating = true);
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
        );
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude
        );
        
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          // Format: "Neighborhood, City" or "Street, City"
          final address = "${place.subLocality ?? place.name}, ${place.locality}";
          if (mounted) Navigator.pop(context, address);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not get location: $e"), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Select Location",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- Search Bar Section ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for a place...",
                prefixIcon: const Icon(Icons.search_rounded, color: primaryColor),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // --- Use Current Location Action ---
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.my_location_rounded, color: primaryColor, size: 20),
            ),
            title: Text(
              _isLocating ? "Locating..." : "Use Current Location", 
              style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text("Best for tagging your exact spot"),
            trailing: _isLocating 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: _isLocating ? null : _getCurrentLocation,
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text("SUGGESTED PLACES", 
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtleText, letterSpacing: 1.2)),
              ],
            ),
          ),

          // --- Suggested Locations ---
          Expanded(
            child: ListView(
              children: [
                _locationTile("Lekki, Lagos", "Lagos State, Nigeria"),
                _locationTile("Ikeja, Lagos", "Lagos State, Nigeria"),
                _locationTile("Abuja, Nigeria", "Federal Capital Territory"),
                _locationTile("Victoria Island", "Lagos, Nigeria"),
                _locationTile("Benin-City", "Edo State, Nigeria"),
                _locationTile("Port Harcourt", "Rivers State, Nigeria"),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _locationTile(String title, String subtitle) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.location_on_outlined, color: Colors.grey),
          title: Text(title, style: const TextStyle(color: textColor, fontWeight: FontWeight.w500)),
          subtitle: Text(subtitle, style: const TextStyle(color: subtleText, fontSize: 12)),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context, title);
          },
        ),
        Divider(indent: 70, endIndent: 16, height: 1, color: Colors.grey[100]),
      ],
    );
  }
}