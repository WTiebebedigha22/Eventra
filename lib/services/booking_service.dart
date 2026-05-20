import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum BookingStatus { pending, accepted, rejected, completed, cancelled }

extension BookingStatusX on BookingStatus {
  String get value => name;
  static BookingStatus from(String s) =>
      BookingStatus.values.firstWhere((e) => e.name == s);
}

class BookingModel {
  final String id;
  final String customerId;
  final String vendorId;
  final String vendorName;
  final String customerName;
  final String eventTitle;
  final String eventDescription;
  final DateTime eventDate;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BookingModel({
    required this.id,
    required this.customerId,
    required this.vendorId,
    required this.vendorName,
    required this.customerName,
    required this.eventTitle,
    required this.eventDescription,
    required this.eventDate,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory BookingModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      customerId: d['customerId'] as String,
      vendorId: d['vendorId'] as String,
      vendorName: d['vendorName'] as String? ?? '',
      customerName: d['customerName'] as String? ?? '',
      eventTitle: d['eventTitle'] as String,
      eventDescription: d['eventDescription'] as String? ?? '',
      eventDate: (d['eventDate'] as Timestamp).toDate(),
      status: BookingStatusX.from(d['status'] as String),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      updatedAt: d['updatedAt'] != null
          ? (d['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  bool get canReview => status == BookingStatus.completed;
  bool get canCancel => status == BookingStatus.pending;
}

class BookingService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference get _bookings => _db.collection('bookings');

  // ─── Create ─────────────────────────────────────────────────────────────

  Future<String> createBooking({
    required String vendorId,
    required String vendorName,
    required String customerName,
    required String eventTitle,
    required String eventDescription,
    required DateTime eventDate,
  }) async {
    final ref = _bookings.doc();
    await ref.set({
      'customerId': _uid,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'customerName': customerName,
      'eventTitle': eventTitle,
      'eventDescription': eventDescription,
      'eventDate': Timestamp.fromDate(eventDate),
      'status': BookingStatus.pending.value,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // ─── Status transitions ──────────────────────────────────────────────────

  Future<void> _updateStatus(String bookingId, BookingStatus status) async {
    await _bookings.doc(bookingId).update({
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptBooking(String bookingId) =>
      _updateStatus(bookingId, BookingStatus.accepted);

  Future<void> rejectBooking(String bookingId) =>
      _updateStatus(bookingId, BookingStatus.rejected);

  Future<void> cancelBooking(String bookingId) =>
      _updateStatus(bookingId, BookingStatus.cancelled);

  Future<void> markCompleted(String bookingId) =>
      _updateStatus(bookingId, BookingStatus.completed);

  // ─── Queries ─────────────────────────────────────────────────────────────

  /// Customer: all their bookings
  Stream<QuerySnapshot> myBookings({BookingStatus? status}) {
    Query q = _bookings
        .where('customerId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true);
    if (status != null) q = q.where('status', isEqualTo: status.value);
    return q.snapshots();
  }

  /// Vendor: all bookings assigned to them
  Stream<QuerySnapshot> vendorBookings({BookingStatus? status}) {
    Query q = _bookings
        .where('vendorId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true);
    if (status != null) q = q.where('status', isEqualTo: status.value);
    return q.snapshots();
  }

  Future<BookingModel?> getBooking(String bookingId) async {
    final doc = await _bookings.doc(bookingId).get();
    if (!doc.exists) return null;
    return BookingModel.fromDoc(doc);
  }

  Stream<DocumentSnapshot> bookingStream(String bookingId) =>
      _bookings.doc(bookingId).snapshots();
}