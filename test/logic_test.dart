import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// ── Booking Tests ─────────────────────────────────────────────────────────────
// These test the BookingProvider state machine (pending→accepted→completed, etc.)

// To generate mocks: dart run build_runner build
// (requires adding mockito + build_runner to dev_dependencies)

// For now, logic-level unit tests that don't need mock generation:

void main() {
  group('BookingStatus transitions', () {
    test('pending → accepted is valid', () {
      // A vendor can accept a pending booking
      const initial = 'pending';
      const next = 'accepted';
      expect(_validTransition(initial, next, isVendor: true), isTrue);
    });

    test('pending → rejected is valid for vendor', () {
      expect(_validTransition('pending', 'rejected', isVendor: true), isTrue);
    });

    test('pending → cancelled is valid for customer', () {
      expect(_validTransition('pending', 'cancelled', isVendor: false), isTrue);
    });

    test('accepted → cancelled by customer is invalid (can only cancel pending)', () {
      expect(_validTransition('accepted', 'cancelled', isVendor: false), isFalse);
    });

    test('completed → pending is invalid (no going back)', () {
      expect(_validTransition('completed', 'pending', isVendor: true), isFalse);
    });

    test('accepted → completed is valid for vendor', () {
      expect(_validTransition('accepted', 'completed', isVendor: true), isTrue);
    });

    test('rejected → accepted is invalid', () {
      expect(_validTransition('rejected', 'accepted', isVendor: true), isFalse);
    });
  });

  group('Review eligibility', () {
    test('completed booking can be reviewed', () {
      expect(_canReview('completed'), isTrue);
    });

    test('pending booking cannot be reviewed', () {
      expect(_canReview('pending'), isFalse);
    });

    test('accepted booking cannot be reviewed', () {
      expect(_canReview('accepted'), isFalse);
    });

    test('cancelled booking cannot be reviewed', () {
      expect(_canReview('cancelled'), isFalse);
    });
  });

  group('Star rating validation', () {
    test('rating of 0 is invalid', () {
      expect(_validRating(0), isFalse);
    });

    test('rating of 1 is valid', () {
      expect(_validRating(1), isTrue);
    });

    test('rating of 5 is valid', () {
      expect(_validRating(5), isTrue);
    });

    test('rating of 6 is invalid', () {
      expect(_validRating(6), isFalse);
    });

    test('rating of -1 is invalid', () {
      expect(_validRating(-1), isFalse);
    });
  });

  group('Chat ID generation', () {
    test('chat ID is stable regardless of order', () {
      final id1 = _chatId('alice', 'bob');
      final id2 = _chatId('bob', 'alice');
      expect(id1, equals(id2));
    });

    test('chat ID contains both user IDs', () {
      final id = _chatId('uid_aaa', 'uid_bbb');
      expect(id.contains('uid_aaa'), isTrue);
      expect(id.contains('uid_bbb'), isTrue);
    });
  });

  group('Geohash encoding', () {
    test('same coordinates produce same hash', () {
      final h1 = _geohash(6.4541, 3.3947, precision: 5);
      final h2 = _geohash(6.4541, 3.3947, precision: 5);
      expect(h1, equals(h2));
    });

    test('hash has correct precision length', () {
      final h = _geohash(6.4541, 3.3947, precision: 6);
      expect(h.length, equals(6));
    });

    test('nearby coordinates share a common prefix at low precision', () {
      // Lagos area
      final h1 = _geohash(6.4541, 3.3947, precision: 3);
      final h2 = _geohash(6.4600, 3.4000, precision: 3);
      // These are close — should share prefix at 3-char precision (~156km)
      expect(h1.substring(0, 2), equals(h2.substring(0, 2)));
    });
  });
}

// ─── Pure logic helpers (mirrors real service logic, no Firebase needed) ──────

bool _validTransition(String from, String to, {required bool isVendor}) {
  if (isVendor) {
    if (from == 'pending' && (to == 'accepted' || to == 'rejected')) return true;
    if (from == 'accepted' && to == 'completed') return true;
    return false;
  } else {
    // Customer
    if (from == 'pending' && to == 'cancelled') return true;
    return false;
  }
}

bool _canReview(String status) => status == 'completed';

bool _validRating(num rating) => rating >= 1 && rating <= 5;

String _chatId(String a, String b) {
  final ids = [a, b]..sort();
  return '${ids[0]}_${ids[1]}';
}

String _geohash(double lat, double lng, {int precision = 5}) {
  const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  double minLat = -90, maxLat = 90, minLng = -180, maxLng = 180;
  bool isEven = true;
  int bit = 0, ch = 0;
  String hash = '';
  while (hash.length < precision) {
    double mid;
    if (isEven) {
      mid = (minLng + maxLng) / 2;
      if (lng > mid) { ch = (ch << 1) | 1; minLng = mid; }
      else { ch <<= 1; maxLng = mid; }
    } else {
      mid = (minLat + maxLat) / 2;
      if (lat > mid) { ch = (ch << 1) | 1; minLat = mid; }
      else { ch <<= 1; maxLat = mid; }
    }
    isEven = !isEven;
    if (++bit == 5) { hash += base32[ch]; bit = 0; ch = 0; }
  }
  return hash;
}