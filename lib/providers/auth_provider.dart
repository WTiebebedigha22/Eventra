import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;

  Stream<User?> get authStateChangesStream => _auth.authStateChanges();

  bool get isLoggedIn => _auth.currentUser != null;

  String? get currentUserEmail {
    return _auth.currentUser?.email;
  }

  Future<void> login(String email, String password) async {
    isLoading = true; notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false; notifyListeners();
    }
  }

  Future<void> signup(String email, String password) async {
    isLoading = true; notifyListeners();
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false; notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }
}