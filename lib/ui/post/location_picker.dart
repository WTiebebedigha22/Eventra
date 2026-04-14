import 'dart:async';
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
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Location> _searchLocations = [];
  List<Placemark> _searchPlacemarks = [];
  Timer? _debounce;

  // --- Theme Colors (Aligned with CreatePost) ---
  static const Color primaryColor = Colors.deepPurple;
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Colors.black54;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- Real-time Search Logic ---
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (_searchController.text.length > 2) {
        _searchPlaces(_searchController.text);
      }
    });
  }

  Future<void> _searchPlaces(String query) async {
    setState(() => _isSearching = true);
    try {
      // Get coordinates from the search string
      List<Location> locations = await locationFromAddress(query);
      
      if (locations.isNotEmpty) {
        // Get address details from those coordinates
        List<Placemark> placemarks = await placemarkFromCoordinates(
          locations.first.latitude, 
          locations.first.longitude
        );
        
        setState(() {
          _searchLocations = locations;
          _searchPlacemarks = placemarks;
        });
      }
    } catch (e) {
      debugPrint("Search error: $e");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  // --- GPS Location Logic ---
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
          final address = "${place.subLocality ?? place.name}, ${place.locality}";
          if (mounted) Navigator.pop(context, address);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location error: $e"), backgroundColor: Colors.redAccent)
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
          icon: const Icon(Icons.close_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Location",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: "Search for cities or places...",
                prefixIcon: const Icon(Icons.search_rounded, color: primaryColor, size: 20),
                suffixIcon: _isSearching 
                  ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                  : (_searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear()) : null),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // --- "Current Location" Button ---
          ListTile(
            onTap: _isLocating ? null : _getCurrentLocation,
            leading: CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.1),
              child: const Icon(Icons.my_location_rounded, color: primaryColor, size: 18),
            ),
            title: Text(
              _isLocating ? "Locating..." : "Use Current Location", 
              style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text("Best for nearby events", style: TextStyle(fontSize: 12)),
            trailing: _isLocating 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ),
          
          const Divider(height: 1),

          // --- Results or Suggestions ---
          Expanded(
            child: _searchController.text.isEmpty 
              ? _buildSuggestionsList() 
              : _buildSearchResultsList(),
          )
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    final List<Map<String, String>> staticPlaces = [
      {"name": "Lekki", "city": "Lagos State"},
      {"name": "Ikeja", "city": "Lagos State"},
      {"name": "Wuse 2", "city": "Abuja, FCT"},
      {"name": "GRA", "city": "Benin City, Edo"},
      {"name": "Trans Amadi", "city": "Port Harcourt"},
    ];

    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text("SUGGESTED PLACES", 
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtleText, letterSpacing: 1.1)),
        ),
        ...staticPlaces.map((p) => _locationTile(p['name']!, p['city']!)),
      ],
    );
  }

  Widget _buildSearchResultsList() {
    if (_searchPlacemarks.isEmpty && !_isSearching) {
      return const Center(child: Text("No places found. Try another search."));
    }
    
    return ListView.builder(
      itemCount: _searchPlacemarks.length,
      itemBuilder: (context, index) {
        final p = _searchPlacemarks[index];
        final name = p.name ?? p.subLocality ?? "Unknown Area";
        final city = "${p.locality ?? ''}, ${p.administrativeArea ?? ''}";
        return _locationTile(name, city);
      },
    );
  }

  Widget _locationTile(String title, String subtitle) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: const Icon(Icons.location_on_outlined, color: Colors.grey, size: 22),
          title: Text(title, style: const TextStyle(color: textColor, fontWeight: FontWeight.w500)),
          subtitle: Text(subtitle, style: const TextStyle(color: subtleText, fontSize: 12)),
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context, "$title, $subtitle");
          },
        ),
        Divider(indent: 64, endIndent: 20, height: 1, color: Colors.grey[100]),
      ],
    );
  }
}