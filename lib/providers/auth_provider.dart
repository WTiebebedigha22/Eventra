import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  
  // 1. STATE FOR ONBOARDING PERSISTENCE
  bool _hasSeenOnboarding = false; 
  static const String _onboardingKey = 'hasSeenOnboarding';

  // State Getters
  Stream<User?> get authStateChangesStream => _auth.authStateChanges();
  bool get isLoggedIn => _auth.currentUser != null;
  String? get currentUserEmail => _auth.currentUser?.email;
  bool get isLoading => _isLoading;

  // Getter required by GoRouter redirect logic
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  // --- Initialization and State Management ---

  // 2. INITIALIZATION METHOD (Called once on app startup)
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load persisted onboarding state
    _hasSeenOnboarding = prefs.getBool(_onboardingKey) ?? false;
    
    // Important: Listen to auth state changes to update the router 
    // immediately if the user's session is restored/expired.
    _auth.authStateChanges().listen((user) {
      notifyListeners(); 
    });
    
    notifyListeners();
  }

  // 3. SETTER FOR ONBOARDING (Called when user completes the onboarding screen)
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = true;
    await prefs.setBool(_onboardingKey, true);
    notifyListeners();
  }

  // --- Authentication Methods ---

  Future<void> login(String email, String password) async {
    _isLoading = true; notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<void> signup(String email, String password) async {
    _isLoading = true; notifyListeners();
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    // Reset loading state just in case
    _isLoading = false;
    notifyListeners();
  }
}