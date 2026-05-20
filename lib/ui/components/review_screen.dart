import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/review_service.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

class ReviewProvider extends ChangeNotifier {
  final ReviewService _service;
  ReviewProvider(this._service);

  bool _loading = false;
  String? _error;
  bool get loading => _loading;
  String? get error => _error;

  Stream<QuerySnapshot> vendorReviews(String vendorId) =>
      _service.vendorReviews(vendorId);

  Future<bool> submitReview({
    required String vendorId,
    required String bookingId,
    required double rating,
    required String body,
    required String customerName,
    String? customerAvatar,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.submitReview(
        vendorId: vendorId,
        bookingId: bookingId,
        rating: rating,
        body: body,
        customerName: customerName,
        customerAvatar: customerAvatar,
      );
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> hasReviewed(String bookingId) =>
      _service.hasReviewed(bookingId);
}

// ─── Submit Review Screen ─────────────────────────────────────────────────────

class SubmitReviewScreen extends StatefulWidget {
  final String vendorId;
  final String vendorName;
  final String bookingId;
  final String customerName;
  final String? customerAvatar;

  const SubmitReviewScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
    required this.bookingId,
    required this.customerName,
    this.customerAvatar,
  });

  @override
  State<SubmitReviewScreen> createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends State<SubmitReviewScreen> {
  double _rating = 0;
  final _bodyCtrl = TextEditingController();

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a star rating')));
      return;
    }
    final provider = context.read<ReviewProvider>();
    final ok = await provider.submitReview(
      vendorId: widget.vendorId,
      bookingId: widget.bookingId,
      rating: _rating,
      body: _bodyCtrl.text,
      customerName: widget.customerName,
      customerAvatar: widget.customerAvatar,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted! Thank you ⭐')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Error submitting review')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReviewProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Leave a Review')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(widget.vendorName,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          const Text('Your Rating', textAlign: TextAlign.center),
          const SizedBox(height: 8),
          _StarRatingPicker(
            value: _rating,
            onChanged: (v) => setState(() => _rating = v),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _bodyCtrl,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Share your experience (optional)',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: provider.loading ? null : _submit,
              child: provider.loading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Text('Submit Review',
                      style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Star Rating Picker ───────────────────────────────────────────────────────

class _StarRatingPicker extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _StarRatingPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final star = i + 1;
        return GestureDetector(
          onTap: () => onChanged(star.toDouble()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              value >= star ? Icons.star_rounded : Icons.star_border_rounded,
              size: 44,
              color: value >= star ? Colors.amber : Colors.grey,
            ),
          ),
        );
      }),
    );
  }
}

// ─── Star Rating Display (read-only) ─────────────────────────────────────────

class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final double size;
  const StarRatingDisplay({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final full = rating >= i + 1;
        final half = !full && rating >= i + 0.5;
        return Icon(
          full
              ? Icons.star_rounded
              : half
                  ? Icons.star_half_rounded
                  : Icons.star_border_rounded,
          size: size,
          color: Colors.amber,
        );
      }),
    );
  }
}

// ─── Vendor Reviews List Widget ───────────────────────────────────────────────

class VendorReviewsList extends StatelessWidget {
  final String vendorId;
  const VendorReviewsList({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReviewProvider>();
    return StreamBuilder<QuerySnapshot>(
      stream: provider.vendorReviews(vendorId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No reviews yet. Be the first!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, i) {
            final review = ReviewModel.fromDoc(docs[i]);
            return _ReviewCard(review: review);
          },
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: review.customerAvatar != null
                ? NetworkImage(review.customerAvatar!)
                : null,
            child: review.customerAvatar == null
                ? Text(review.customerName[0].toUpperCase())
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(review.customerName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(
                      DateFormat('MMM d, yyyy').format(review.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                StarRatingDisplay(rating: review.rating),
                if (review.body.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(review.body),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}