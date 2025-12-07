import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    bool hasPermission = await Geolocator.isLocationServiceEnabled();
    if (!hasPermission) {
      await Geolocator.requestPermission();
    }
    return Geolocator.getCurrentPosition();
  }

  LatLng toLatLng(Position p) => LatLng(p.latitude, p.longitude);
}
