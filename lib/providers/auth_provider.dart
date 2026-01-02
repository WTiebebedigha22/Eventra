import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
<<<<<<< HEAD
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
=======
import 'package:firebase_storage/firebase_storage.dart';
>>>>>>> 175e0ad1666df687fd104c4994b60c006a602e26

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // -----------------------------
  // STATE
  // -----------------------------
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _hasSeenOnboarding = false;

  static const String _onboardingKey = 'hasSeenOnboarding';
  static const String _imgBBKey = '5558a317e6889711facf0a9502619fc0';

  // Profile data
  String? _firstName;
  String? _lastName;
  String? _bio;
  DateTime? _dob;
  DateTime? _createdAt;
<<<<<<< HEAD
  
  // Stats & Posts State
  int _eventCount = 0;
  int _followerCount = 0;
  int _followingCount = 0;
  List<Map<String, dynamic>> _userEvents = [];

  String? profilePhotoUrl; 
=======
  String? profilePhotoUrl;

  // Event Management State
  List<Map<String, dynamic>> _userEvents = [];
  List<Map<String, dynamic>> _savedEvents = [];
  List<Map<String, dynamic>> _attendedEvents = [];
>>>>>>> 175e0ad1666df687fd104c4994b60c006a602e26

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

  int get eventCount => _eventCount;
  int get followerCount => _followerCount;
  int get followingCount => _followingCount;
  List<Map<String, dynamic>> get userEvents => _userEvents;

  // -----------------------------
  // INITIALIZATION & LOADING
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

<<<<<<< HEAD
=======
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
>>>>>>> 175e0ad1666df687fd104c4994b60c006a602e26
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
<<<<<<< HEAD
      
      _followerCount = data['followerCount'] ?? 0;
      _followingCount = data['followingCount'] ?? 0;

      profilePhotoUrl = data['photoURL'] ?? _auth.currentUser?.photoURL;

      await fetchUserEvents();
      
=======
      profilePhotoUrl = data['photoUrl'] ?? _auth.currentUser?.photoURL;
>>>>>>> 175e0ad1666df687fd104c4994b60c006a602e26
    } catch (e) {
      debugPrint('Profile load error: $e');
    }
  }

<<<<<<< HEAD
  Future<void> fetchUserEvents() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('creatorId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      _userEvents = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      _eventCount = _userEvents.length;
    } catch (e) {
      debugPrint('Error fetching user events: $e');
    }
=======
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
>>>>>>> 175e0ad1666df687fd104c4994b60c006a602e26
    notifyListeners();
  }

  // -----------------------------
<<<<<<< HEAD
  // CREATE POST / EVENT
  // -----------------------------
  Future<void> createPost({
    required String title,
    required String description,
    required File imageFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception("User must be logged in to post.");

      // 1. Upload Image to ImgBB
      final bytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: {
          'key': _imgBBKey,
          'image': base64Image,
        },
      );

      if (response.statusCode != 200) {
        throw Exception("Image upload failed: ${response.body}");
      }

      final data = jsonDecode(response.body);
      final String imageUrl = data['data']['url'];

      // 2. Add Document to Firestore
      await _firestore.collection('events').add({
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'creatorId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Refresh list
      await fetchUserEvents();
      
    } catch (e) {
      debugPrint('Exception: Failed to create post: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // -----------------------------
  // PHOTO UPLOAD (ImgBB)
  // -----------------------------
  Future<void> uploadProfilePicture(File file) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final bytes = await file.readAsBytes();
      String base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: {
          'key': _imgBBKey,
          'image': base64Image,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String uploadedUrl = data['data']['url'];

        await user.updatePhotoURL(uploadedUrl);
        await _firestore.collection('users').doc(user.uid).update({
          'photoURL': uploadedUrl,
        });

        profilePhotoUrl = uploadedUrl;
      }
    } catch (e) {
      debugPrint('Upload error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // -----------------------------
  // AUTH & UTILS
  // -----------------------------
=======
  // AUTH LOGIC (TUNED)
  // -----------------------------
>>>>>>> 175e0ad1666df687fd104c4994b60c006a602e26
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
        'eventCount': 0,
        'followerCount': 0,
        'followingCount': 0,
      });

      _firstName = username;
      _lastName = '';
      _bio = '';
      _eventCount = 0;
      _userEvents = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _clearProfile() {
    _firstName = _lastName = _bio = null;
    _dob = _createdAt = null;
    _eventCount = _followerCount = _followingCount = 0;
    _userEvents = [];
    profilePhotoUrl = null;
    notifyListeners();
  }

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

  Future<void> logout() async {
    await _auth.signOut();
  }

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
<<<<<<< HEAD

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
=======
}
>>>>>>> 175e0ad1666df687fd104c4994b60c006a602e26
