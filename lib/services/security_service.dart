import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecurityService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  /// Stream security settings
  Stream<Map<String, dynamic>?> getSettings() {
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('security')
        .doc('settings')
        .snapshots()
        .map((doc) => doc.data());
  }

  /// Update settings
  Future<void> updateSettings(Map<String, dynamic> data) async {
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('security')
        .doc('settings')
        .set({
      ...data,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Password reset
  Future<void> sendPasswordReset() async {
    final email = _auth.currentUser?.email;
    if (email != null) {
      await _auth.sendPasswordResetEmail(email: email);
    }
  }

  /// Device logging (basic structure)
  Future<void> logDevice(String deviceName) async {
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('security')
        .doc('devices')
        .collection('list')
        .add({
      'device': deviceName,
      'loginAt': FieldValue.serverTimestamp(),
    });
  }
}