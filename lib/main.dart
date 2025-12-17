import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'app/app.dart';
import 'config/firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/post_provider.dart'; // Ensure this path is correct

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. OneSignal Initialization (New v5.x Syntax)
  // Remove OneSignal.shared; use the static class directly
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose); 
  OneSignal.initialize("729c13e9-37c8-4881-b376-2e8441e04a35");
  
  // Request push notification permissions
  OneSignal.Notifications.requestPermission(true);

  // 3. Initialize Auth
  final authProvider = AuthProvider();
  await authProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
        ),
        // Adding PostProvider since we used it in the CreatePostScreen
        ChangeNotifierProvider(create: (_) => PostProvider()),
        
        // Add other providers here as you build them (e.g., EventProvider, ChatProvider)
      ],
      child: const EventraApp(),
    ),
  );
}