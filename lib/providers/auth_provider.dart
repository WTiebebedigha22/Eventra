import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_storage/firebase_storage.dart'; 
import 'package:flutter/foundation.dart'; // for debugPrint

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  bool _isLoading = false;
  
  bool _hasSeenOnboarding = false; 
  static const String _onboardingKey = 'hasSeenOnboarding';

  // --- 💡 UPDATED PROFILE STATE (Mirrors data stored in Firestore) ---
  String? _currentUserFirstName; // NEW
  String? _currentUserLastName;  // NEW
  DateTime? _currentUserDOB;     // NEW
  String? _currentBio;
  

  // State Getters
  Stream<User?> get authStateChangesStream => _auth.authStateChanges();
  bool get isLoggedIn => _auth.currentUser != null;
  String? get currentUserEmail => _auth.currentUser?.email;
  bool get isLoading => _isLoading;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  // --- 💡 UPDATED REAL PROFILE GETTERS ---
  String get currentUserName => _auth.currentUser?.displayName ?? 'Guest';
  String? get profilePhotoUrl => _auth.currentUser?.photoURL;
  
  // Full Name is now derived from First and Last Name for display consistency
  String get currentUserFullName {
        if (_currentUserFirstName != null && _currentUserLastName != null) {
            return '${_currentUserFirstName!} ${_currentUserLastName!}';
        }
        if (_currentUserFirstName != null) return _currentUserFirstName!;
        return 'Update your Full Name';
    }
    
  String get currentUserFirstName => _currentUserFirstName ?? '';  // NEW Getter
  String get currentUserLastName => _currentUserLastName ?? '';  // NEW Getter
  DateTime? get currentUserDOB => _currentUserDOB;               // NEW Getter
  
  String get currentBio => _currentBio ?? 'No bio yet. Tell people about yourself!';

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

  // 💡 UPDATED: Fetch all new profile fields
  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _currentUserFirstName = data['firstName'] as String?; // NEW
        _currentUserLastName = data['lastName'] as String?;  // NEW
        _currentBio = data['bio'] as String?;
        
        // Handle Timestamp to DateTime conversion for DOB
        final dobTimestamp = data['dob'] as Timestamp?;
        _currentUserDOB = dobTimestamp?.toDate();           // NEW
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    } finally {
      notifyListeners();
    }
  }

  void _clearProfileData() {
    _currentUserFirstName = null; // UPDATED
    _currentUserLastName = null;  // UPDATED
    _currentUserDOB = null;        // UPDATED
    _currentBio = null;
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
        
        // 1. Set default display name (Username)
        await user.updateDisplayName(defaultUsername);
        
        // 2. 💡 UPDATED: Create initial Firestore user document with new fields
        await _firestore.collection('users').doc(user.uid).set({ 
          'email': email,
          'firstName': defaultUsername, // Default first name
          'lastName': '',              // Default empty last name
          'bio': '', 
          'createdAt': FieldValue.serverTimestamp(),
          'dob': null,                 // Default null DOB
        });
        
        // 3. Initialize local state after creation
        _currentUserFirstName = defaultUsername;
        _currentUserLastName = '';
        _currentUserDOB = null;
        _currentBio = '';
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

  // --- 💡 REAL PROFILE UPDATE METHOD (UPDATED SIGNATURE AND LOGIC) ---
  
  Future<void> updateProfile({
    required String username, 
    required String firstName,  // NEW
    required String lastName,   // NEW
    required String bio,
    DateTime? dob,              // NEW
  }) async {
    _isLoading = true; notifyListeners();
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // 1. Update Firebase Authentication user displayName (Username)
        await user.updateDisplayName(username);
        
        // 2. Update Cloud Firestore document with all fields
        await _firestore.collection('users').doc(user.uid).update({ 
          'firstName': firstName, 
          'lastName': lastName, 
          'bio': bio, 
          'dob': dob != null ? Timestamp.fromDate(dob) : null, // Convert DateTime to Timestamp
          'updatedAt': FieldValue.serverTimestamp()
        });
        
        // 3. Update local state
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

  // This method handles the real logic for photo upload (Unchanged)
  Future<void> uploadProfilePicture(File imageFile) async {
    _isLoading = true; notifyListeners();
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // 1. Upload file to Firebase Storage
        final storageRef = _storage.ref().child('profile_photos/${user.uid}/profile.jpg');
        await storageRef.putFile(imageFile);
        
        // 2. Get the new download URL
        final downloadUrl = await storageRef.getDownloadURL();
        
        // 3. Update Firebase Authentication user photoURL
        await user.updatePhotoURL(downloadUrl);
        
        // 4. The UI listens to profilePhotoUrl which comes from _auth.currentUser,
        // so notifyListeners will prompt the refresh.
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false; 
      notifyListeners(); 
    }
  }
}

