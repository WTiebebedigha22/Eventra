import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final _messaging = FirebaseMessaging.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Initialize FCM + save token
  Future<void> init() async {
    await _messaging.requestPermission();

    final token = await _messaging.getToken();
    final uid = _auth.currentUser?.uid;

    if (uid != null && token != null) {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('notifications')
          .set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }
  }

  /// Enable / Disable notifications at device level
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (enabled) {
      await _messaging.subscribeToTopic('all');
    } else {
      await _messaging.unsubscribeFromTopic('all');
    }
  }

  /// Save user preferences
  Future<void> updateSettings(Map<String, dynamic> data) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notifications')
        .set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Stream settings
  Stream<Map<String, dynamic>?> getSettings() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notifications')
        .snapshots()
        .map((doc) => doc.data());
  }
}