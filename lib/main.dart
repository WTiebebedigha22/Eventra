import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider; 
import 'package:provider/provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'app/app.dart';
import 'config/firebase_options.dart';
import 'providers/auth_provider.dart'; 
import 'providers/post_provider.dart';
import 'services/chat_service.dart';
import 'services/booking_service.dart'; // NEW: Import the Booking Service

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. OneSignal Initialization
  OneSignal.Debug.setLogLevel(OSLogLevel.none); 
  OneSignal.initialize("729c13e9-37c8-4881-b376-2e8441e04a35");
  OneSignal.Notifications.requestPermission(true);

  // 3. Initialize Auth Provider & Sync Identity
  final authProvider = AuthProvider();
  await authProvider.initialize();

  // Sync OneSignal with Firebase UID immediately if already logged in
  final User? firebaseUser = FirebaseAuth.instance.currentUser;
  if (firebaseUser != null) {
    _syncUserWithOneSignal(firebaseUser);
  }

  // 4. Global Notification Click Listener
  OneSignal.Notifications.addClickListener((event) {
    final data = event.notification.additionalData;
    debugPrint('Notification Data received: $data');
    // Logic for deep-linking (e.g., opening a specific chat or ticket) goes here
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
        ),
        ChangeNotifierProvider(create: (_) => ChatService()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        // NEW: BookingService added to global provider tree
        ChangeNotifierProvider(create: (_) => BookingService()), 
      ],
      child: const EventraApp(),
    ),
  );
}

/// Helper function to sync Firebase Identity with OneSignal
void _syncUserWithOneSignal(User user) {
  // Links the OneSignal device record to the Firebase UID
  OneSignal.login(user.uid);
  
  // Sets user properties for targeted notification segments
  if (user.email != null) {
    OneSignal.User.addEmail(user.email!);
  }
  
  if (user.displayName != null) {
    // FIXED: OneSignal addTags expects a Map<String, String>
    OneSignal.User.addTags({"name": user.displayName!});
  }
}