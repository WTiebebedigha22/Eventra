class LocationPoint {
  final double latitude;
  final double longitude;

  LocationPoint({required this.latitude, required this.longitude});

  factory LocationPoint.fromMap(Map<String, dynamic>? map) {
    if (map == null) return LocationPoint(latitude: 0, longitude: 0);
    return LocationPoint(
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {'latitude': latitude, 'longitude': longitude};
}
