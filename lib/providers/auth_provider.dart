import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_storage/firebase_storage.dart'; 
import 'package:flutter/foundation.dart'; 

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  bool _isLoading = false;
  
  bool _hasSeenOnboarding = false; 
  static const String _onboardingKey = 'hasSeenOnboarding';

  // --- PROFILE STATE ---
  String? _currentUserFirstName; 
  String? _currentUserLastName;  
  DateTime? _currentUserDOB;     
  String? _currentBio;
  DateTime? _currentUserCreatedAt;

  // --- STATE GETTERS ---
  Stream<User?> get authStateChangesStream => _auth.authStateChanges();
  bool get isLoggedIn => _auth.currentUser != null;
  String? get currentUserEmail => _auth.currentUser?.email;
  bool get isLoading => _isLoading;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  // --- PROFILE GETTERS ---
  String get currentUserName => _auth.currentUser?.displayName ?? 'Guest';
  String? get profilePhotoUrl => _auth.currentUser?.photoURL;

  String get currentUserFullName {
    if (_currentUserFirstName != null && _currentUserLastName != null) {
      return '${_currentUserFirstName!} ${_currentUserLastName!}';
    }
    if (_currentUserFirstName != null) return _currentUserFirstName!;
    return 'Update your Full Name';
  }

  String get currentUserFirstName => _currentUserFirstName ?? ''; 
  String get currentUserLastName => _currentUserLastName ?? ''; 
  DateTime? get currentUserDOB => _currentUserDOB; 
  DateTime? get currentUserCreatedAt => _currentUserCreatedAt;
  String get currentBio => _currentBio ?? 'No bio yet.';

  // --- INITIALIZATION ---

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool(_onboardingKey) ?? false;
    
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _fetchUserData(user.uid); 
      } else {
        _clearProfileData();
      }
      notifyListeners(); 
    });

    notifyListeners();
  }

  // --- FETCH USER DATA ---

  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _currentUserFirstName = data['firstName'];
        _currentUserLastName = data['lastName'];
        _currentBio = data['bio'];

        final dobTimestamp = data['dob'] as Timestamp?;
        _currentUserDOB = dobTimestamp?.toDate();

        final createdAtTimestamp = data['createdAt'] as Timestamp?;
        _currentUserCreatedAt = createdAtTimestamp?.toDate();
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    } finally {
      notifyListeners();
    }
  }

  void _clearProfileData() {
    _currentUserFirstName = null;
    _currentUserLastName = null;
    _currentUserDOB = null;
    _currentBio = null;
    _currentUserCreatedAt = null;
    notifyListeners();
  }

  // --- ONBOARDING ---

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = true;
    await prefs.setBool(_onboardingKey, true);
    notifyListeners();
  }

  // --- AUTHENTICATION ---

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signup(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user != null) {
        final username = email.split('@')[0];
        await user.updateDisplayName(username);

        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'firstName': username,
          'lastName': '',
          'bio': '',
          'createdAt': FieldValue.serverTimestamp(),
          'dob': null,
        });

        _currentUserFirstName = username;
        _currentUserLastName = '';
        _currentBio = '';
        _currentUserCreatedAt = DateTime.now();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _clearProfileData();
    notifyListeners();
  }

  // --- FORGOT PASSWORD (NEW) ---

  Future<void> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Reset password error: ${e.message}');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- PROFILE UPDATE ---

  Future<void> updateProfile({
    required String username,
    required String firstName,
    required String lastName,
    required String bio,
    DateTime? dob,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(username);

        await _firestore.collection('users').doc(user.uid).update({
          'firstName': firstName,
          'lastName': lastName,
          'bio': bio,
          'dob': dob != null ? Timestamp.fromDate(dob) : null,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        _currentUserFirstName = firstName;
        _currentUserLastName = lastName;
        _currentBio = bio;
        _currentUserDOB = dob;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- PROFILE PHOTO ---

  Future<void> uploadProfilePicture(File imageFile) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final ref = _storage.ref('profile_pictures/${user.uid}.jpg');
        await ref.putFile(imageFile);
        final url = await ref.getDownloadURL();
        await user.updatePhotoURL(url);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
