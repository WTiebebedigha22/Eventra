import 'package:flutter/material.dart';
import '../models/common/location_point.dart';
import '../services/map_service.dart';

class LocationProvider extends ChangeNotifier {
  final MapService _map = MapService();

  LocationPoint? currentLocation;

  Future<void> fetchCurrentLocation() async {
    currentLocation = await _map.getCurrentLocation();
    notifyListeners();
  }
}
