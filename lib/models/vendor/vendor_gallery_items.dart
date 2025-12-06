import 'package:cloud_firestore/cloud_firestore.dart';

class VendorGalleryItem {
  final String url;
  final String type; // image or video
  final DateTime uploadedAt;

  VendorGalleryItem({
    required this.url,
    required this.type,
    required this.uploadedAt,
  });

  factory VendorGalleryItem.fromMap(Map<String, dynamic> map) {
    return VendorGalleryItem(
      url: map['url'],
      type: map['type'],
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'type': type,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }
}
