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

  // --- UPDATED PROFILE STATE (Mirrors data stored in Firestore) ---
  String? _currentUserFirstName; 
  String? _currentUserLastName;  
  DateTime? _currentUserDOB;     
  String? _currentBio;
    DateTime? _currentUserCreatedAt; // 💡 NEW: Creation date state
  

  // State Getters
  Stream<User?> get authStateChangesStream => _auth.authStateChanges();
  bool get isLoggedIn => _auth.currentUser != null;
  String? get currentUserEmail => _auth.currentUser?.email;
  bool get isLoading => _isLoading;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  // --- REAL PROFILE GETTERS ---
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
    DateTime? get currentUserCreatedAt => _currentUserCreatedAt; // 💡 NEW GETTER
  
  String get currentBio => _currentBio ?? 'No bio yet.';

  // --- Initialization and State Management ---

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

  // 💡 UPDATED: Fetch creation date from Firestore
  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _currentUserFirstName = data['firstName'] as String?; 
        _currentUserLastName = data['lastName'] as String?;  
        _currentBio = data['bio'] as String?;
        
        final dobTimestamp = data['dob'] as Timestamp?;
        _currentUserDOB = dobTimestamp?.toDate();           

        // 💡 NEW: Retrieve createdAt Timestamp and convert it
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
    _currentUserCreatedAt = null; // 💡 Clear new state
    notifyListeners();
  }

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
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;
      if (user != null) {
        final defaultUsername = email.split('@')[0];
        final creationDate = DateTime.now(); // Local time for initial state
        
        await user.updateDisplayName(defaultUsername);
        
        // 💡 Firestore document uses server timestamp
        await _firestore.collection('users').doc(user.uid).set({ 
          'email': email,
          'firstName': defaultUsername, 
          'lastName': '',              
          'bio': '', 
          'createdAt': FieldValue.serverTimestamp(), // 💡 The source of truth
          'dob': null,                 
        });
        
        // Initialize local state after creation (Note: _fetchUserData is triggered on auth change)
        _currentUserFirstName = defaultUsername;
        _currentUserLastName = '';
        _currentUserDOB = null;
        _currentBio = '';
        _currentUserCreatedAt = creationDate; // 💡 Initialize local state for immediate use
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _clearProfileData();
    _isLoading = false;
    notifyListeners();
  }

  // --- PROFILE UPDATE METHODS (No change needed here) ---
  
  Future<void> updateProfile({
    required String username, 
    required String firstName,  
    required String lastName,   
    required String bio,
    DateTime? dob,              
  }) async {
    _isLoading = true; notifyListeners();
    try {
      final user = _auth.currentUser;
      if (user != null) {
        
        await user.updateDisplayName(username);
        
        await _firestore.collection('users').doc(user.uid).update({ 
          'firstName': firstName, 
          'lastName': lastName, 
          'bio': bio, 
          'dob': dob != null ? Timestamp.fromDate(dob) : null, 
          'updatedAt': FieldValue.serverTimestamp()
        });
        
        _currentUserFirstName = firstName;
        _currentUserLastName = lastName;
        _currentBio = bio;
        _currentUserDOB = dob;
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false; 
      notifyListeners(); 
    }
  }

  // Photo upload remains unchanged
  Future<void> uploadProfilePicture(File imageFile) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final storageRef = _storage.ref().child('profile_pictures/${user.uid}.jpg');
        await storageRef.putFile(imageFile);
        final photoUrl = await storageRef.getDownloadURL();
        await user.updatePhotoURL(photoUrl);
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
  