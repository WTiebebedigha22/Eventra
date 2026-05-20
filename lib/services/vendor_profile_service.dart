import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

const kVendorCategories = [
  'Wedding Planner',
  'Corporate Events',
  'Birthday Parties',
  'Photography',
  'Catering',
  'Music & DJ',
  'Decoration',
  'Venue',
  'Other',
];

class VendorProfile {
  final String uid;
  final String displayName;
  final String? bio;
  final String? photoUrl;
  final String? category;
  final String? location;
  final double? lat;
  final double? lng;
  final String? geohash;
  final List<String> portfolioImages;
  final double averageRating;
  final int reviewCount;
  final bool isAvailable;

  const VendorProfile({
    required this.uid,
    required this.displayName,
    this.bio,
    this.photoUrl,
    this.category,
    this.location,
    this.lat,
    this.lng,
    this.geohash,
    this.portfolioImages = const [],
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.isAvailable = true,
  });

  factory VendorProfile.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VendorProfile(
      uid: doc.id,
      displayName: d['displayName'] as String? ?? '',
      bio: d['bio'] as String?,
      photoUrl: d['photoUrl'] as String?,
      category: d['category'] as String?,
      location: d['location'] as String?,
      lat: (d['lat'] as num?)?.toDouble(),
      lng: (d['lng'] as num?)?.toDouble(),
      geohash: d['geohash'] as String?,
      portfolioImages: List<String>.from(d['portfolioImages'] as List? ?? []),
      averageRating: (d['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (d['reviewCount'] as num?)?.toInt() ?? 0,
      isAvailable: d['isAvailable'] as bool? ?? true,
    );
  }
}

class VendorProfileService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference get _vendors => _db.collection('vendors');

  Future<VendorProfile?> getProfile(String uid) async {
    final doc = await _vendors.doc(uid).get();
    if (!doc.exists) return null;
    return VendorProfile.fromDoc(doc);
  }

  Stream<DocumentSnapshot> profileStream(String uid) =>
      _vendors.doc(uid).snapshots();

  /// Create or update vendor profile
  Future<void> upsertProfile({
    required String displayName,
    String? bio,
    String? category,
    String? location,
    double? lat,
    double? lng,
    String? geohashValue,
    bool isAvailable = true,
  }) async {
    await _vendors.doc(_uid).set({
      'displayName': displayName,
      'bio': bio,
      'category': category,
      'location': location,
      'lat': lat,
      'lng': lng,
      'geohash': geohashValue,
      'isAvailable': isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Mirror displayName to users collection
    await _db.collection('users').doc(_uid).update({
      'displayName': displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Pick and upload profile photo; returns download URL
  Future<String?> uploadProfilePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return null;

    final compressed = await _compressImage(File(picked.path));
    if (compressed == null) return null;

    final ref = _storage.ref('profile_photos/$_uid.jpg');
    await ref.putFile(compressed);
    final url = await ref.getDownloadURL();

    await _vendors.doc(_uid).set({'photoUrl': url}, SetOptions(merge: true));
    await _db.collection('users').doc(_uid).update({'photoUrl': url});
    return url;
  }

  /// Pick and upload a portfolio image; returns download URL
  Future<String?> addPortfolioImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return null;

    final compressed = await _compressImage(File(picked.path));
    if (compressed == null) return null;

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref =
        _storage.ref('portfolio/$_uid/$fileName');
    await ref.putFile(compressed);
    final url = await ref.getDownloadURL();

    await _vendors.doc(_uid).update({
      'portfolioImages': FieldValue.arrayUnion([url]),
    });
    return url;
  }

  Future<void> removePortfolioImage(String url) async {
    await _vendors.doc(_uid).update({
      'portfolioImages': FieldValue.arrayRemove([url]),
    });
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }

  /// Toggle availability (e.g. vendor goes on vacation)
  Future<void> setAvailability(bool available) async {
    await _vendors.doc(_uid)
        .set({'isAvailable': available}, SetOptions(merge: true));
  }

  /// Browse vendors with optional category filter and search text
  Stream<QuerySnapshot> browseVendors({String? category}) {
    Query q = _vendors.where('isAvailable', isEqualTo: true);
    if (category != null) q = q.where('category', isEqualTo: category);
    return q.orderBy('averageRating', descending: true).snapshots();
  }

  Future<File?> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 75,
      minWidth: 800,
      minHeight: 800,
    );
    return result != null ? File(result.path) : null;
  }
}