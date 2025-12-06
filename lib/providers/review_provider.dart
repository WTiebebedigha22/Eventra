import 'package:flutter/material.dart';
import '../models/reviews/review.dart';
import '../services/firestore_service.dart';

class ReviewProvider extends ChangeNotifier {
  final FirestoreService _db = FirestoreService();

  List<Review> reviews = [];

  Future<void> loadReviews(String vendorId) async {
    reviews = await _db.getReviews(vendorId);
    notifyListeners();
  }

  Future<void> addReview(Review review) async {
    await _db.addReview(review);
    reviews.add(review);
    notifyListeners();
  }
}
