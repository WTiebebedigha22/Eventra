import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewService {
  final _ref = FirebaseFirestore.instance.collection('reviews');

  Future<void> addReview(ReviewModel review) async {
    await _ref.add(review.toMap());
  }

  Stream<List<ReviewModel>> streamVendorReviews(String vendorId) {
    return _ref
        .where("vendorId", isEqualTo: vendorId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((e) => ReviewModel.fromMap(e.data(), e.id)).toList());
  }
}
