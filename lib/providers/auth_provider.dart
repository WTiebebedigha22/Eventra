import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // FIX: Updated to use the .standard() factory constructor required by recent versions
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard(
    scopes: <String>['email'],
  );

  StreamSubscription? _userEventsSub;
  StreamSubscription? _bookmarksSub;
  StreamSubscription? _attendedSub;

  // -----------------------------
  // STATE
  // -----------------------------
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _hasSeenOnboarding = false;

  static const String _onboardingKey = 'hasSeenOnboarding';
  static const String _imgBBKey = '5558a317e6889711facf0a9502619fc0';

  String? _displayName;
  String? _firstName;
  String? _lastName;
  String? _bio;
  DateTime? _dob;
  DateTime? _createdAt;
  String? _profilePhotoUrl;

  int _followerCount = 0;
  int _followingCount = 0;
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

  String get displayName => _displayName ?? _auth.currentUser?.displayName ?? 'User';
  String get userId => currentUser?.uid ?? '';
  String get firstName => _firstName ?? '';
  String get lastName => _lastName ?? '';
  String get bio => _bio ?? 'No bio yet.';
  DateTime? get dob => _dob;
  DateTime? get createdAt => _createdAt;
  String? get photoURL => _profilePhotoUrl ?? _auth.currentUser?.photoURL;
  String get currentUserEmail => _auth.currentUser?.email ?? '';

  String get fullName => (_firstName != null && _firstName!.isNotEmpty && _lastName != null)
      ? '$_firstName $_lastName'
      : displayName;

  int get eventCount => _userEvents.length;
  int get followerCount => _followerCount;
  int get followingCount => _followingCount;

  List<Map<String, dynamic>> get userEvents => _userEvents;
  List<Map<String, dynamic>> get savedEvents => _savedEvents;
  List<Map<String, dynamic>> get attendedEvents => _attendedEvents;

  // -----------------------------
  // INITIALIZATION & LISTENERS
  // -----------------------------
  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool(_onboardingKey) ?? false;

    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await _loadUserProfile(user.uid);
        _listenToUserActivity(user.uid);
      } else {
        _clearProfile();
      }
      _isInitializing = false;
      notifyListeners();
    });
  }

  void _listenToUserActivity(String uid) {
    _cancelSubscriptions();

    _userEventsSub = _firestore
        .collection('events')
        .where('creatorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _userEvents = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      notifyListeners();
    });

    _bookmarksSub = _firestore
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .snapshots()
        .listen((snapshot) {
      _savedEvents = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      notifyListeners();
    });

    _attendedSub = _firestore
        .collection('users')
        .doc(uid)
        .collection('attended')
        .snapshots()
        .listen((snapshot) {
      _attendedEvents = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      notifyListeners();
    });
  }

  // -----------------------------
  // AUTHENTICATION METHODS
  // -----------------------------

  Future<void> signup({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = cred.user;
      if (user == null) return;

      final String fname = userData['firstName'] ?? '';
      final String lname = userData['lastName'] ?? '';
      final String uname = userData['username'] ?? email.split('@')[0];
      final String gender = userData['gender'] ?? 'Not Specified';

      await user.updateDisplayName(uname);

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'username': uname,
        'displayName': uname,
        'firstName': fname,
        'lastName': lname,
        'gender': gender,
        'bio': 'Hey there! I am using Ventra.',
        'photoURL': null,
        'followerCount': 0,
        'followingCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _displayName = uname;
      _firstName = fname;
      _lastName = lname;
    } catch (e) {
      debugPrint("Signup Error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint("Login Error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Trigger the Google sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 2. Fetch authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // FIX: Accessing tokens correctly from the auth object
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          List<String> nameParts = (user.displayName ?? "Ventra User").split(' ');
          String fName = nameParts.first;
          String lName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
          String baseUname = (user.email ?? "user").split('@')[0];
          String generatedUsername = '$baseUname${Random().nextInt(999)}';

          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'username': generatedUsername,
            'displayName': user.displayName ?? generatedUsername,
            'firstName': fName,
            'lastName': lName,
            'gender': 'Not Specified',
            'bio': 'Hey there! I am using Ventra.',
            'photoURL': user.photoURL,
            'followerCount': 0,
            'followingCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        await _loadUserProfile(user.uid);
      }
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _clearProfile();
  }

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

  // -----------------------------
  // PROFILE & SOCIAL METHODS
  // -----------------------------

  Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
    return null;
  }

  Future<void> toggleFollow(String targetUid, bool isFollowing) async {
    final myUid = userId;
    if (myUid.isEmpty || myUid == targetUid) return;

    final targetUserRef = _firestore.collection('users').doc(targetUid);
    final currentUserRef = _firestore.collection('users').doc(myUid);
    final followerDocRef = targetUserRef.collection('followers').doc(myUid);

    try {
      if (!isFollowing) {
        await followerDocRef.set({'followedAt': FieldValue.serverTimestamp()});
        await targetUserRef.update({'followerCount': FieldValue.increment(1)});
        await currentUserRef.update({'followingCount': FieldValue.increment(1)});
      } else {
        await followerDocRef.delete();
        await targetUserRef.update({'followerCount': FieldValue.increment(-1)});
        await currentUserRef.update({'followingCount': FieldValue.increment(-1)});
      }
      await _loadUserProfile(myUid); 
    } catch (e) {
      debugPrint('Follow Toggle Error: $e');
      rethrow;
    }
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        await _ensureUserDocumentExists(uid);
        return;
      }

      final data = doc.data()!;
      _displayName = data['displayName'];
      _firstName = data['firstName'];
      _lastName = data['lastName'];
      _bio = data['bio'];
      _dob = (data['dob'] as Timestamp?)?.toDate();
      _createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      _profilePhotoUrl = data['photoURL'];
      _followerCount = data['followerCount'] ?? 0;
      _followingCount = data['followingCount'] ?? 0;
    } catch (e) {
      debugPrint('Profile load error: $e');
    }
    notifyListeners();
  }

  Future<void> _ensureUserDocumentExists(String uid) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': user.email,
      'username': user.email?.split('@')[0] ?? 'user',
      'displayName': user.displayName ?? 'Ventra User',
      'bio': 'Hey there! I am using Ventra.',
      'followerCount': 0,
      'followingCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    await _loadUserProfile(uid);
  }

  Future<void> updateProfile({
    required String displayName,
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

      await user.updateDisplayName(displayName);
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': displayName,
        'firstName': firstName,
        'lastName': lastName,
        'bio': bio,
        'dob': dob != null ? Timestamp.fromDate(dob) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _displayName = displayName;
      _firstName = firstName;
      _lastName = lastName;
      _bio = bio;
      _dob = dob;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> _uploadToImgBB(File file) async {
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
      return data['data']['url'];
    } else {
      throw Exception("ImgBB Upload Failed: ${response.body}");
    }
  }

  Future<void> uploadProfilePicture(File file) async {
    _isLoading = true;
    notifyListeners();
    try {
      final url = await _uploadToImgBB(file);
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePhotoURL(url);
        await _firestore.collection('users').doc(user.uid).update({'photoURL': url});
        _profilePhotoUrl = url;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createPost({
    required String title,
    required String description,
    required File imageFile,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final imageUrl = await _uploadToImgBB(imageFile);

      await _firestore.collection('events').add({
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'creatorId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // -----------------------------
  // CLEANUP & HELPERS
  // -----------------------------
  void _clearProfile() {
    _cancelSubscriptions();
    _displayName = _firstName = _lastName = _bio = null;
    _dob = _createdAt = _profilePhotoUrl = null;
    _followerCount = _followingCount = 0;
    _userEvents = [];
    _savedEvents = [];
    _attendedEvents = [];
    notifyListeners();
  }

  void _cancelSubscriptions() {
    _userEventsSub?.cancel();
    _bookmarksSub?.cancel();
    _attendedSub?.cancel();
  }

  Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    _hasSeenOnboarding = true;
    notifyListeners();
  }
}
