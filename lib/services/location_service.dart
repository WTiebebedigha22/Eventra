import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LatLng {
  final double lat;
  final double lng;
  const LatLng(this.lat, this.lng);
}

class LocationService {
  static final LocationService _instance = LocationService._();
  factory LocationService() => _instance;
  LocationService._();

  Position? _lastPosition;
  Position? get lastPosition => _lastPosition;

  /// Request permission and get current location
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    _lastPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    return _lastPosition;
  }

  /// Convert coordinates to a human-readable address
  Future<String?> getAddressFromCoords(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      return [p.street, p.locality, p.administrativeArea, p.country]
          .where((s) => s != null && s.isNotEmpty)
          .join(', ');
    } catch (_) {
      return null;
    }
  }

  /// Convert an address string to coordinates
  Future<LatLng?> getCoordsFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) return null;
      return LatLng(locations.first.latitude, locations.first.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Simple Haversine distance in km between two points
  double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _toRad(double deg) => deg * pi / 180;

  /// Encodes a lat/lng to a geohash prefix (5 chars = ~5km precision)
  /// This lets Firestore do basic geo-range queries without Algolia.
  String geohash(double lat, double lng, {int precision = 5}) {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    double minLat = -90, maxLat = 90, minLng = -180, maxLng = 180;
    bool isEven = true;
    int bit = 0, ch = 0;
    String hash = '';

    while (hash.length < precision) {
      double mid;
      if (isEven) {
        mid = (minLng + maxLng) / 2;
        if (lng > mid) { ch = (ch << 1) | 1; minLng = mid; }
        else { ch <<= 1; maxLng = mid; }
      } else {
        mid = (minLat + maxLat) / 2;
        if (lat > mid) { ch = (ch << 1) | 1; minLat = mid; }
        else { ch <<= 1; maxLat = mid; }
      }
      isEven = !isEven;
      if (++bit == 5) { hash += base32[ch]; bit = 0; ch = 0; }
    }
    return hash;
  }

  /// Query vendors within ~radiusKm of a point using geohash prefix range.
  /// For production, replace with Geoflutterfire2 or Algolia Geo Search.
  Future<List<DocumentSnapshot>> nearbyVendors(
    double lat,
    double lng, {
    double radiusKm = 20,
    String? category,
  }) async {
    final db = FirebaseFirestore.instance;
    final hash = geohash(lat, lng, precision: 4); // ~40km cell

    Query q = db
        .collection('vendors')
        .orderBy('geohash')
        .startAt([hash])
        .endAt(['$hash~']);

    if (category != null) q = q.where('category', isEqualTo: category);

    final snap = await q.get();

    // Client-side precise filter
    return snap.docs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      final vLat = (d['lat'] as num?)?.toDouble();
      final vLng = (d['lng'] as num?)?.toDouble();
      if (vLat == null || vLng == null) return false;
      return distanceKm(lat, lng, vLat, vLng) <= radiusKm;
    }).toList();
  }
}

// ─── Location Permission Guard Widget ────────────────────────────────────────

class LocationPermissionGuard extends StatefulWidget {
  final Widget child;
  final Widget? denied;

  const LocationPermissionGuard({
    super.key,
    required this.child,
    this.denied,
  });

  @override
  State<LocationPermissionGuard> createState() =>
      _LocationPermissionGuardState();
}

class _LocationPermissionGuardState extends State<LocationPermissionGuard> {
  LocationPermission? _permission;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final p = await Geolocator.checkPermission();
    if (mounted) setState(() => _permission = p);
  }

  @override
  Widget build(BuildContext context) {
    if (_permission == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_permission == LocationPermission.denied ||
        _permission == LocationPermission.deniedForever) {
      return widget.denied ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Location access is needed to find planners near you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await Geolocator.openAppSettings();
                      await _check();
                    },
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            ),
          );
    }
    return widget.child;
  }
}