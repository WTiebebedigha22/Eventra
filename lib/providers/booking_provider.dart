import 'package:flutter/material.dart';
import '../models/booking/booking.dart';
import '../services/notification_service.dart';

class BookingProvider extends ChangeNotifier {
  final FirestoreService _db = FirestoreService();

  List<Booking> bookings = [];
  bool isLoading = false;

  Future<void> getUserBookings(String userId) async {
    isLoading = true;
    notifyListeners();

    bookings = await _db.getUserBookings(userId);

    isLoading = false;
    notifyListeners();
  }

  Future<void> createBooking(Booking booking) async {
    await _db.createBooking(booking);
    bookings.add(booking);
    notifyListeners();
  }

  Future<void> updateBookingStatus(String id, String status) async {
    await _db.updateBookingStatus(id, status);

    final booking = bookings.firstWhere((b) => b.id == id);
    booking.status = status;

    notifyListeners();
  }
}
