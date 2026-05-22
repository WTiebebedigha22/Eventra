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

class _LocationPickerScreenState extends State<LocationPickerScreen> with SingleTickerProviderStateMixin {
  bool _isLocating = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Location> _searchLocations = [];
  List<Placemark> _searchPlacemarks = [];
  Timer? _debounce;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // --- Theme Colors (Updated to Deep Purple) ---
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B85FF);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Color(0xFF7A7E8B);
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // --- Real-time Search Logic ---
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.length > 2) {
        _searchPlaces(_searchController.text);
      } else if (_searchController.text.isEmpty) {
        setState(() {
          _searchPlacemarks = [];
          _searchLocations = [];
        });
      }
    });
  }

  Future<void> _searchPlaces(String query) async {
    setState(() => _isSearching = true);
    try {
      List<Location> locations = await locationFromAddress(query);
      
      if (locations.isNotEmpty) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          locations.first.latitude, 
          locations.first.longitude
        );
        
        setState(() {
          _searchLocations = locations;
          _searchPlacemarks = placemarks;
        });
      } else {
        setState(() {
          _searchPlacemarks = [];
          _searchLocations = [];
        });
      }
    } catch (e) {
      debugPrint("Search error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Search failed: ${e.toString().split(':').first}')),
              ],
            ),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // --- GPS Location Logic ---
  Future<void> _getCurrentLocation() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLocating = true);
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServicesDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDeniedDialog();
        return;
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, 
          position.longitude
        );
        
        if (placemarks.isNotEmpty && mounted) {
          final place = placemarks.first;
          String address = _formatAddress(place);
          HapticFeedback.selectionClick();
          Navigator.pop(context, address);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.gps_off, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Unable to get location: ${e.toString().split(':').first}')),
              ],
            ),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  String _formatAddress(Placemark place) {
    String area = place.subLocality ?? place.name ?? place.thoroughfare ?? '';
    String city = place.locality ?? place.administrativeArea ?? '';
    String country = place.country ?? '';
    
    if (area.isNotEmpty && city.isNotEmpty) {
      return "$area, $city";
    } else if (city.isNotEmpty) {
      return city;
    } else if (country.isNotEmpty) {
      return country;
    }
    return "Current Location";
  }

  void _showLocationServicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Location Services Disabled'),
        content: const Text('Please enable location services to use this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Location Permission Required'),
        content: const Text('We need location access to show nearby places.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _getCurrentLocation();
            },
            child: const Text('Allow', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Permission Denied'),
        content: const Text('Location permission was permanently denied. Please enable it in app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              _buildSearchBar(),
              _buildCurrentLocationButton(),
              const Divider(height: 1, color: Color(0xFFF0F2F5)),
              Expanded(
                child: _searchController.text.isEmpty 
                  ? _buildSuggestionsList() 
                  : _buildSearchResultsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(fontSize: 16, color: textColor),
        decoration: InputDecoration(
          hintText: "Search cities or places...",
          hintStyle: TextStyle(color: subtleText.withValues(alpha: 0.6), fontSize: 15),
          prefixIcon: Icon(Icons.search_rounded, color: primaryColor, size: 22),
          suffixIcon: _isSearching 
            ? Container(
                width: 20,
                margin: const EdgeInsets.all(12),
                child: const CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
              )
            : (_searchController.text.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                    onPressed: () => _searchController.clear(),
                  )
                : null),
          filled: true,
          fillColor: Colors.grey.withValues(alpha: 0.08),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentLocationButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor.withValues(alpha: 0.05), primaryLight.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: _isLocating ? null : _getCurrentLocation,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isLocating ? Icons.gps_fixed : Icons.my_location_rounded,
            color: primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          _isLocating ? "Locating..." : "Use Current Location", 
          style: const TextStyle(
            color: primaryColor, 
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: const Text("Get your precise location", style: TextStyle(fontSize: 12)),
        trailing: _isLocating 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    final List<Map<String, String>> popularPlaces = [
      {"name": "Lekki Phase 1", "city": "Lagos, Nigeria"},
      {"name": "Ikeja GRA", "city": "Lagos, Nigeria"},
      {"name": "Wuse 2", "city": "Abuja, FCT"},
      {"name": "GRA", "city": "Port Harcourt, Rivers"},
      {"name": "Victoria Island", "city": "Lagos, Nigeria"},
      {"name": "Ajah", "city": "Lagos, Nigeria"},
      {"name": "Maitama", "city": "Abuja, FCT"},
      {"name": "GRA", "city": "Benin City, Edo"},
      {"name": "Trans Amadi", "city": "Port Harcourt, Rivers"},
      {"name": "Magodo", "city": "Lagos, Nigeria"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "POPULAR LOCATIONS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: subtleText,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: popularPlaces.length,
            itemBuilder: (context, index) {
              final place = popularPlaces[index];
              return _locationTile(place['name']!, place['city']!);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultsList() {
    if (_searchPlacemarks.isEmpty && !_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              "No places found",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: subtleText),
            ),
            const SizedBox(height: 8),
            Text(
              "Try a different search term",
              style: TextStyle(fontSize: 14, color: subtleText.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _searchPlacemarks.length,
      itemBuilder: (context, index) {
        final p = _searchPlacemarks[index];
        final name = p.name ?? p.subLocality ?? p.thoroughfare ?? "Unknown Area";
        String city = p.locality ?? p.administrativeArea ?? '';
        String country = p.country ?? '';
        
        String subtitle = city.isNotEmpty ? city : country;
        
        return _locationTile(name, subtitle);
      },
    );
  }

  Widget _locationTile(String title, String subtitle) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_on_outlined, color: primaryColor, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 15),
          ),
          subtitle: subtitle.isNotEmpty 
              ? Text(
                  subtitle,
                  style: const TextStyle(color: subtleText, fontSize: 12),
                )
              : null,
          trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          onTap: () {
            HapticFeedback.selectionClick();
            final result = subtitle.isNotEmpty ? "$title, $subtitle" : title;
            Navigator.pop(context, result);
          },
        ),
        if (title != "Magodo") 
          Divider(indent: 72, endIndent: 20, height: 1, color: Colors.grey.withValues(alpha: 0.1)),
      ],
    );
  }
}