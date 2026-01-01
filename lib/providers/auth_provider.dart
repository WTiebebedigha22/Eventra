import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  String? profilePhotoUrl;

  // Event Management State
  List<Map<String, dynamic>> _userEvents = [];
  List<Map<String, dynamic>> _savedEvents = [];
  List<Map<String, dynamic>> _attendedEvents = [];

  // -----------------------------
  // GETTERS
  // -----------------------------
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  bool get isLoggedIn => _auth.currentUser != null;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  User? get currentUser => _auth.currentUser;

  String get fullName => (_firstName != null && _lastName != null) 
      ? '$_firstName $_lastName' 
      : (_firstName ?? _auth.currentUser?.displayName ?? 'User');

  String get currentBio => _bio ?? 'No bio yet.';
  String get currentUserFullName => fullName;
  DateTime? get createdAt => _createdAt;
  String? get photoURL => _auth.currentUser?.photoURL ?? profilePhotoUrl;
  String? get currentUserEmail => _auth.currentUser?.email;

  // Event Getters for the UI
  List<Map<String, dynamic>> get userEvents => _userEvents;
  List<Map<String, dynamic>> get savedEvents => _savedEvents;
  List<Map<String, dynamic>> get attendedEvents => _attendedEvents;

  // -----------------------------
  // INITIALIZATION
  // -----------------------------
  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool(_onboardingKey) ?? false;

    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await _loadUserProfile(user.uid);
        _listenToUserActivity(user.uid); // Start listening to events/saves
      } else {
        _clearProfile();
      }
      notifyListeners();
    });

    _isInitializing = false;
    notifyListeners();
  }

  // -----------------------------
  // EVENT & ACTIVITY LISTENERS
  // -----------------------------
  // This connects your app to real-time updates for the Profile Screen
  void _listenToUserActivity(String uid) {
    // 1. Listen to Events Created by User
    _firestore.collection('events')
        .where('organizerId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      _userEvents = snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
      notifyListeners();
    });

    // 2. Listen to Saved/Bookmarked Events
    // Assuming a 'bookmarks' sub-collection under user
    _firestore.collection('users').doc(uid).collection('bookmarks')
        .snapshots()
        .listen((snapshot) {
      _savedEvents = snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
      notifyListeners();
    });

    // 3. Listen to Attended/Past Events
    _firestore.collection('users').doc(uid).collection('attended')
        .snapshots()
        .listen((snapshot) {
      _attendedEvents = snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
      notifyListeners();
    });
  }

  // -----------------------------
  // PROFILE LOAD & CLEAR
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
      profilePhotoUrl = data['photoUrl'] ?? _auth.currentUser?.photoURL;
    } catch (e) {
      debugPrint('Profile load error: $e');
    }
  }

  void _clearProfile() {
    _firstName = null;
    _lastName = null;
    _bio = null;
    _dob = null;
    _createdAt = null;
    profilePhotoUrl = null;
    _userEvents = [];
    _savedEvents = [];
    _attendedEvents = [];
    notifyListeners();
  }

  // -----------------------------
  // AUTH LOGIC (TUNED)
  // -----------------------------
  Future<void> signup(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = cred.user;
      if (user == null) return;

      final username = email.split('@')[0];
      
      // Initialize a proper User Document for a Social App
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'firstName': username,
        'lastName': '',
        'bio': 'Hey there! I am using Ventra.',
        'photoUrl': null,
        'followerCount': 0,
        'followingCount': 0,
        'eventCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _firstName = username;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // -----------------------------
  // PROFILE UPDATE
  // -----------------------------
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String bio,
    DateTime? dob,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      await _firestore.collection('users').doc(uid).update({
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
}
