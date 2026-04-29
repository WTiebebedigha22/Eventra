import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class BookingService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ---------------------------------------------------------------------------
  // 1. Sync ticket to the top-level `bookings` collection.
  //    Called fire-and-forget from TicketPurchaseScreen AFTER the ticket has
  //    already been written to users/{uid}/tickets. This method does NOT
  //    duplicate that write — it only syncs a lightweight booking record used
  //    for admin queries and gate scanning.
  // ---------------------------------------------------------------------------
  Future<void> purchaseTicket({
    required String eventId,
    required String ticketId,       // pass the ID already created in the screen
    required String eventTitle,
    required String eventImageUrl,
    required String eventDate,
    required String eventLocation,
    required double price,
    required int quantity,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User must be logged in to book.");

    try {
      final double totalAmount = price * quantity;

      await _firestore.collection('bookings').doc(ticketId).set({
        'userId': uid,
        'eventId': eventId,
        'ticketId': ticketId,
        'eventTitle': eventTitle,
        'eventImageUrl': eventImageUrl,
        'eventDate': eventDate,
        'eventLocation': eventLocation,
        'totalAmount': totalAmount,
        'quantity': quantity,
        'bookingStatus': 'pending',       // becomes 'confirmed' after payment
        'qrCodeData': 'eventra_verify_$ticketId',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("BookingService sync error: $e");
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Called by PaymentScreen after successful payment — marks the booking
  //    record confirmed and updates the user's ticket in one batch.
  // ---------------------------------------------------------------------------
  Future<void> confirmPayment({
    required String ticketId,
    required String paymentMethod,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User must be logged in.");

    _setLoading(true);

    try {
      final batch = _firestore.batch();

      // Mark booking confirmed
      final bookingRef = _firestore.collection('bookings').doc(ticketId);
      batch.update(bookingRef, {
        'bookingStatus': 'confirmed',
        'paymentMethod': paymentMethod,
        'paidAt': FieldValue.serverTimestamp(),
      });

      // Mark user ticket valid
      final ticketRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('tickets')
          .doc(ticketId);
      batch.update(ticketRef, {
        'isPaid': true,
        'isValid': true,
        'paymentMethod': paymentMethod,
        'paidAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      debugPrint("BookingService confirmPayment error: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Real-time stream of the current user's confirmed tickets
  // ---------------------------------------------------------------------------
  Stream<QuerySnapshot> getUserTicketsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .where('bookingStatus', isEqualTo: 'confirmed')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ---------------------------------------------------------------------------
  // 4. Fetch a specific booking record
  // ---------------------------------------------------------------------------
  Future<DocumentSnapshot> getTicketDetails(String ticketId) {
    return _firestore.collection('bookings').doc(ticketId).get();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}