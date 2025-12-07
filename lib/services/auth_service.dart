import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'user_service.dart';
import 'app_exceptions.dart';

class AuthService {
  final FirebaseAuth _firebase = FirebaseAuth.instance;
  final UserService _userService = UserService();

  Stream<User?> authStateChanges() => _firebase.authStateChanges();

  User? get currentUser => _firebase.currentUser;

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final cred = await _firebase.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserModel(
        id: cred.user!.uid,
        name: name,
        email: email,
        createdAt: DateTime.now(),
      );

      await _userService.createUser(user);
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? "Signup failed", code: e.code);
    }
  }

  Future<UserModel?> login(String email, String password) async {
    try {
      await _firebase.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return await _userService.getUser(_firebase.currentUser!.uid);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? "Login failed", code: e.code);
    }
  }

  Future<void> logout() => _firebase.signOut();

  Future<void> resetPassword(String email) async {
    await _firebase.sendPasswordResetEmail(email: email);
  }
}
