import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LanguageService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  Future<void> setLanguage(String lang) async {
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('preferences')
        .set({
      'language': lang,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<String> getLanguage() {
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('preferences')
        .snapshots()
        .map((doc) => doc.data()?['language'] ?? 'en_US');
  }
}