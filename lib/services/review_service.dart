import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewModel {
  final String id;
  final String customerId;
  final String customerName;
  final String? customerAvatar;
  final String vendorId;
  final String bookingId;
  final double rating;
  final String body;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerAvatar,
    required this.vendorId,
    required this.bookingId,
    required this.rating,
    required this.body,
    required this.createdAt,
  });

  factory ReviewModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      customerId: d['customerId'] as String,
      customerName: d['customerName'] as String? ?? 'Anonymous',
      customerAvatar: d['customerAvatar'] as String?,
      vendorId: d['vendorId'] as String,
      bookingId: d['bookingId'] as String,
      rating: (d['rating'] as num).toDouble(),
      body: d['body'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }
}

class ReviewService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  /// Post a review. Checks server-side (and guards client-side) that:
  /// 1. The booking exists and is completed
  /// 2. The current user is the customer
  /// 3. No duplicate review for the same booking
  Future<void> submitReview({
    required String vendorId,
    required String bookingId,
    required double rating,
    required String body,
    required String customerName,
    String? customerAvatar,
  }) async {
    // Guard: check booking status
    final bookingDoc =
        await _db.collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) throw Exception('Booking not found');
    final bdata = bookingDoc.data()!;
    if (bdata['status'] != 'completed') {
      throw Exception('You can only review completed bookings');
    }
    if (bdata['customerId'] != _uid) {
      throw Exception('Not authorised to review this booking');
    }

    // Guard: no duplicate review for this booking
    final existing = await _db
        .collection('reviews')
        .where('bookingId', isEqualTo: bookingId)
        .where('customerId', isEqualTo: _uid)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('You have already reviewed this booking');
    }

    // Write review + update vendor averageRating in a transaction
    await _db.runTransaction((tx) async {
      final vendorRef = _db.collection('vendors').doc(vendorId);
      final vendorSnap = await tx.get(vendorRef);

      final reviewRef = _db.collection('reviews').doc();
      tx.set(reviewRef, {
        'customerId': _uid,
        'customerName': customerName,
        'customerAvatar': customerAvatar,
        'vendorId': vendorId,
        'bookingId': bookingId,
        'rating': rating,
        'body': body.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update vendor's rolling average
      if (vendorSnap.exists) {
        final vdata = vendorSnap.data()!;
        final oldCount = (vdata['reviewCount'] as num?)?.toInt() ?? 0;
        final oldAvg = (vdata['averageRating'] as num?)?.toDouble() ?? 0.0;
        final newCount = oldCount + 1;
        final newAvg = ((oldAvg * oldCount) + rating) / newCount;
        tx.update(vendorRef, {
          'averageRating': double.parse(newAvg.toStringAsFixed(1)),
          'reviewCount': newCount,
        });
      }
    });
  }

  /// All reviews for a vendor
  Stream<QuerySnapshot> vendorReviews(String vendorId) {
    return _db
        .collection('reviews')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Has the current user already reviewed a specific booking?
  Future<bool> hasReviewed(String bookingId) async {
    final snap = await _db
        .collection('reviews')
        .where('bookingId', isEqualTo: bookingId)
        .where('customerId', isEqualTo: _uid)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }
}