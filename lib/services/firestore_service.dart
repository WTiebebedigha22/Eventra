import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user/app_user.dart';
import '../models/vendor/vendor.dart';
import '../models/booking/booking.dart';
import '../models/reviews/review.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // Users
  Future<void> createUser(AppUser user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  Future<AppUser?> getUser(String id) async {
    final doc = await _db.collection('users').doc(id).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!, doc.id);
  }

  // Vendors
  Future<List<Vendor>> getVendors() async {
    final snap = await _db.collection('vendors').get();
    return snap.docs.map((d) => Vendor.fromMap(d.data(), d.id)).toList();
  }

  Future<Vendor> getVendor(String id) async {
    final doc = await _db.collection('vendors').doc(id).get();
    return Vendor.fromMap(doc.data()!, doc.id);
  }

  // Events/bookings
  Future<void> createBooking(Booking b) async {
    await _db.collection('bookings').add(b.toMap());
  }

  Future<List<Booking>> getUserBookings(String userId) async {
    final snap = await _db.collection('bookings').where('userId', isEqualTo: userId).get();
    return snap.docs.map((d) => Booking.fromMap(d.data(), d.id)).toList();
  }

  // Reviews
  Future<void> addReview(Review r) async {
    await _db.collection('reviews').add(r.toMap());
  }

  Future<List<Review>> getReviewsForVendor(String vendorId) async {
    final snap = await _db.collection('reviews').where('vendorId', isEqualTo: vendorId).get();
    return snap.docs.map((d) => Review.fromMap(d.data(), d.id)).toList();
  }
}
