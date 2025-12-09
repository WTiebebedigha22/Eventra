import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/booking/booking.dart';

class BookingProvider extends ChangeNotifier {
  final FirestoreService _db = FirestoreService();
  List<Booking> bookings = [];

  Future<void> loadUserBookings(String userId) async {
    bookings = await _db.getUserBookings(userId);
    notifyListeners();
  }

  Future<void> createBooking(Booking b) async {
    await _db.createBooking(b);
    bookings.add(b);
    notifyListeners();
  }
}
