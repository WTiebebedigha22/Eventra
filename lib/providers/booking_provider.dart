import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _service;
  BookingProvider(this._service);

  bool _loading = false;
  String? _error;
  bool get loading => _loading;
  String? get error => _error;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void _setError(String? v) {
    _error = v;
    notifyListeners();
  }

  Stream<QuerySnapshot> myBookings({BookingStatus? status}) =>
      _service.myBookings(status: status);

  Stream<QuerySnapshot> vendorBookings({BookingStatus? status}) =>
      _service.vendorBookings(status: status);

  Stream<DocumentSnapshot> bookingStream(String id) =>
      _service.bookingStream(id);

  Future<String?> createBooking({
    required String vendorId,
    required String vendorName,
    required String customerName,
    required String eventTitle,
    required String eventDescription,
    required DateTime eventDate,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final id = await _service.createBooking(
        vendorId: vendorId,
        vendorName: vendorName,
        customerName: customerName,
        eventTitle: eventTitle,
        eventDescription: eventDescription,
        eventDate: eventDate,
      );
      return id;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> acceptBooking(String id) => _act(() => _service.acceptBooking(id));
  Future<bool> rejectBooking(String id) => _act(() => _service.rejectBooking(id));
  Future<bool> cancelBooking(String id) => _act(() => _service.cancelBooking(id));
  Future<bool> markCompleted(String id) => _act(() => _service.markCompleted(id));

  Future<bool> _act(Future<void> Function() fn) async {
    _setLoading(true);
    _setError(null);
    try {
      await fn();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
}