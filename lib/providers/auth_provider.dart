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

  // -----------------------------
  // STATE
  // -----------------------------
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _hasSeenOnboarding = false;

  static const String _onboardingKey = 'hasSeenOnboarding';

  // Profile data
  String? _firstName;
  String? _lastName;
  String? _bio;
  DateTime? _dob;
  DateTime? _createdAt;

  String? profilePhotoUrl; // stores uploaded photo URL

  // -----------------------------
  // GETTERS
  // -----------------------------
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  bool get isLoggedIn => _auth.currentUser != null;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  User? get currentUser => _auth.currentUser;

  String get displayName => _auth.currentUser?.displayName ?? 'Guest';
  String? get photoURL => _auth.currentUser?.photoURL ?? profilePhotoUrl;

  String get fullName {
    if (_firstName != null && _lastName != null) {
      return '$_firstName $_lastName';
    }
    return _firstName ?? _auth.currentUser?.displayName ?? 'Guest';
  }

  String get bio => _bio ?? 'No bio yet.';
  String get currentUserFullName => fullName;
  String get currentUserFirstName => _firstName ?? '';
  String get currentUserLastName => _lastName ?? '';
  String get currentBio => _bio ?? '';
  DateTime? get currentUserDOB => _dob;
  String? get currentUserEmail => _auth.currentUser?.email;
  DateTime? get createdAt => _createdAt;

  // -----------------------------
  // INITIALIZATION
  // -----------------------------
  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool(_onboardingKey) ?? false;

    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadUserProfile(user.uid);
      } else {
        _clearProfile();
      }
      notifyListeners();
    });

    _isInitializing = false;
    notifyListeners();
  }

  // -----------------------------
  // PROFILE LOAD
  // -----------------------------
  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      _firstName = data['firstName'];
      _lastName = data['lastName'];
      _bio = data['bio'];
      _dob = (data['dob'] as Timestamp?)?.toDate();
      _createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      profilePhotoUrl = _auth.currentUser?.photoURL;
    } catch (e) {
      debugPrint('Profile load error: $e');
    }
    notifyListeners();
  }

  void _clearProfile() {
    _firstName = null;
    _lastName = null;
    _bio = null;
    _dob = null;
    _createdAt = null;
    profilePhotoUrl = null;
    notifyListeners();
  }

  // -----------------------------
  // ONBOARDING
  // -----------------------------
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    _hasSeenOnboarding = true;
    notifyListeners();
  }

  // -----------------------------
  // AUTH
  // -----------------------------
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
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
      if (user == null) return;

      final username = email.split('@')[0];
      await user.updateDisplayName(username);

      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'firstName': username,
        'lastName': '',
        'bio': '',
        'dob': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _firstName = username;
      _lastName = '';
      _bio = '';
      profilePhotoUrl = user.photoURL;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _clearProfile();
  }

  // -----------------------------
  // PROFILE UPDATE
  // -----------------------------
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
      if (user == null) return;

      await user.updateDisplayName(username);

      await _firestore.collection('users').doc(user.uid).update({
        'firstName': firstName,
        'lastName': lastName,
        'bio': bio,
        'dob': dob != null ? Timestamp.fromDate(dob) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _firstName = firstName;
      _lastName = lastName;
      _bio = bio;
      _dob = dob;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // -----------------------------
  // PROFILE PHOTO
  // -----------------------------
  Future<void> uploadProfilePicture(File file) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final ref = _storage.ref('profile_pictures/${user.uid}.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await user.updatePhotoURL(url);

      profilePhotoUrl = url;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // -----------------------------
  // PASSWORD RESET
  // -----------------------------
  Future<void> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
