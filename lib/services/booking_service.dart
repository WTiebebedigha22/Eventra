import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class BookingService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final String _bookingCollection = 'bookings';
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // --- 1. Purchase Ticket (Sync with Firestore) ---
  Future<void> purchaseTicket({
    required String eventId,
    required String eventTitle,
    required String eventImageUrl,
    required String eventDate,
    required String eventLocation,
    required double price,
    required int quantity,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User must be logged in to book.");

    _setLoading(true);

    try {
      final double totalAmount = price * quantity;

      // Generate a unique Ticket ID
      final String ticketId = 'EVN-${DateTime.now().millisecondsSinceEpoch}-${uid.substring(0, 4)}'.toUpperCase();

      final bookingData = {
        'userId': uid,
        'eventId': eventId,
        'eventTitle': eventTitle,
        'eventImageUrl': eventImageUrl,
        'eventDate': eventDate,
        'eventLocation': eventLocation,
        'totalAmount': totalAmount,
        'quantity': quantity,
        'ticketId': ticketId,
        'bookingStatus': 'confirmed', // confirmed, cancelled, attended
        'createdAt': FieldValue.serverTimestamp(),
        'qrCodeData': 'eventra_verify_$ticketId', // Used for scanning at the gate
      };

      // Use a batch write to ensure data integrity
      WriteBatch batch = _firestore.batch();
      
      DocumentReference bookingRef = _firestore.collection(_bookingCollection).doc();
      batch.set(bookingRef, bookingData);

      // (Optional) Update the event's ticket count logic here
      // DocumentReference eventRef = _firestore.collection('events').doc(eventId);
      // batch.update(eventRef, {'ticketsSold': FieldValue.increment(quantity)});

      await batch.commit();
    } catch (e) {
      debugPrint("Booking Error: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // --- 2. Real-Time "My Tickets" Stream ---
  Stream<QuerySnapshot> getUserTicketsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection(_bookingCollection)
        .where('userId', isEqualTo: uid)
        .where('bookingStatus', isEqualTo: 'confirmed')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // --- 3. Get Specific Ticket Details ---
  Future<DocumentSnapshot> getTicketDetails(String bookingId) {
    return _firestore.collection(_bookingCollection).doc(bookingId).get();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}