import '../common/location_point.dart';

class Vendor {
  final String id;
  final String ownerId;
  final String businessName;
  final String categoryId;
  final String description;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final LocationPoint location;
  final bool verified;

  Vendor({
    required this.id,
    required this.ownerId,
    required this.businessName,
    required this.categoryId,
    required this.description,
    required this.images,
    required this.rating,
    required this.reviewCount,
    required this.location,
    required this.verified,
  });

  factory Vendor.fromMap(Map<String, dynamic> data, String id) {
    return Vendor(
      id: id,
      ownerId: data['ownerId'] ?? '',
      businessName: data['businessName'] ?? '',
      categoryId: data['categoryId'] ?? '',
      description: data['description'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      location: LocationPoint.fromMap(data['location']),
      verified: data['verified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'businessName': businessName,
      'categoryId': categoryId,
      'description': description,
      'images': images,
      'rating': rating,
      'reviewCount': reviewCount,
      'location': location.toMap(),
      'verified': verified,
    };
  }
}
