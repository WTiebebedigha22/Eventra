import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String vendorId;
  final DateTime date;
  final String status;

  Booking({
    required this.id,
    required this.userId,
    required this.vendorId,
    required this.date,
    required this.status,
  });

  factory Booking.fromMap(Map<String, dynamic> data, String id) {
    return Booking(
      id: id,
      userId: data['userId'],
      vendorId: data['vendorId'],
      date: (data['date'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'vendorId': vendorId,
      'date': Timestamp.fromDate(date),
      'status': status,
    };
  }
}
