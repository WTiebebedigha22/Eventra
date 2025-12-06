import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user/app_user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _db = FirestoreService();

  AppUser? currentUser;
  bool isLoading = false;

  AuthProvider() {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authService.userStream.listen((user) async {
      if (user == null) {
        currentUser = null;
      } else {
        currentUser = await _db.getUser(user.uid);
      }
      notifyListeners();
    });
  }

  Future<String?> login(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      return await _authService.login(email, password);
    } catch (e) {
      return e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signup(AppUser user, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      final uid = await _authService.signup(user.email, password);

      if (uid != null) {
        await _db.createUser(user.copyWith(id: uid));
      }
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}