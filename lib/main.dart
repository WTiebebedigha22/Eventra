import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// 1. Resolve conflict by hiding the Firebase version of AuthProvider
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider; 
import 'package:provider/provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'app/app.dart';
import 'config/firebase_options.dart';
import 'providers/auth_provider.dart'; // Your custom provider
import 'providers/post_provider.dart';
import 'providers/chat_provider.dart';
import 'services/chat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. OneSignal Initialization (v5.x)
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("729c13e9-37c8-4881-b376-2e8441e04a35");
  OneSignal.Notifications.requestPermission(true);

  // 3. Initialize your Custom Auth Provider
  final authProvider = AuthProvider();
  await authProvider.initialize();

  // --- OPTION B: Direct Firebase Auth Check ---
  // We use 'User' and 'FirebaseAuth' directly to avoid the getter error
  final User? firebaseUser = FirebaseAuth.instance.currentUser;

  if (firebaseUser != null) {
    // Link OneSignal to the Firebase UID for targeted notifications
    OneSignal.login(firebaseUser.uid);
    
    // Standard: Sync email for advanced OneSignal segments
    if (firebaseUser.email != null) {
      OneSignal.User.addEmail(firebaseUser.email!);
    }
  }

  // --- STANDARD: NOTIFICATION CLICK LISTENER ---
  OneSignal.Notifications.addClickListener((event) {
    final data = event.notification.additionalData;
    debugPrint('NOTIFICATION CLICKED: $data');
  });

  runApp(
    MultiProvider(
      providers: [
        // Use .value since we already initialized authProvider above
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
        ),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(ChatService()),
        ),
      ],
      child: const EventraApp(),
    ),
  );
}