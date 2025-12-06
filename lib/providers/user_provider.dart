import 'package:flutter/material.dart';
import '../models/user/app_user.dart';
import '../services/firestore_service.dart';

class UserProvider extends ChangeNotifier {
  final FirestoreService _db = FirestoreService();

  AppUser? user;
  bool isLoading = false;

  Future<void> loadUser(String userId) async {
    isLoading = true;
    notifyListeners();

    user = await _db.getUser(userId);

    isLoading = false;
    notifyListeners();
  }

  Future<void> updateUser(AppUser updated) async {
    await _db.updateUser(updated);
    user = updated;
    notifyListeners();
  }
}
