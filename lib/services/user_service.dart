import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'app_exceptions.dart';

class UserService {
  final _ref = FirebaseFirestore.instance.collection('users');

  Future<void> createUser(UserModel user) async {
    try {
      await _ref.doc(user.id).set(user.toMap());
    } catch (_) {
      throw FirebaseException("Cannot create user");
    }
  }

  Future<UserModel?> getUser(String id) async {
    try {
      final doc = await _ref.doc(id).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (_) {
      throw FirebaseException("Cannot fetch user");
    }
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    await _ref.doc(id).update(data);
  }
}
