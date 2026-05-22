import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Your Imports
import 'package:ventra/providers/chat_provider.dart';
import 'app/app.dart';
import 'config/app_config.dart';
import 'config/firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/post_provider.dart';
import 'providers/theme_provider.dart';
import 'services/chat_service.dart';
import 'services/booking_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Set language code to suppress X-Firebase-Locale null warning
    await FirebaseAuth.instance.setLanguageCode('en');

    // Firestore Stability Configuration
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // App Check Configuration (comment out if having issues)
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
    } catch (e) {
      debugPrint("App Check error (non-critical): $e");
    }
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    "Unable to connect",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Failed to initialize the app. Please check your connection and try again.\n\nDetails: $e",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  // OneSignal Setup
  _initOneSignal();

  // Auth & State initialization
  final authProvider = AuthProvider();
  await authProvider.initialize();

  // Sync user if already logged in
  final User? firebaseUser = FirebaseAuth.instance.currentUser;
  if (firebaseUser != null) {
    _syncUserWithOneSignal(firebaseUser);
  }

  // Theme Initialization
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('theme') ?? 'System';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),

        // Theme Provider
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(savedTheme),
        ),

        // FIXED: Add ChatService as a provider
        Provider<ChatService>(
          create: (_) => ChatService(),
        ),

        // FIXED: ChatProvider now depends on ChatService
        ChangeNotifierProvider<ChatProvider>(
          create: (context) => ChatProvider(context.read<ChatService>()),
        ),

        ChangeNotifierProvider<PostProvider>(
          create: (_) => PostProvider(),
        ),

        // BookingService as a provider
        Provider<BookingService>(
          create: (_) => BookingService(),
        ),
      ],
      child: const EventraApp(),
    ),
  );
}

// ---------------------------------------------------------------------------
// OneSignal
// ---------------------------------------------------------------------------

void _initOneSignal() {
  OneSignal.Debug.setLogLevel(OSLogLevel.none);

  OneSignal.initialize(AppConfig.oneSignalAppId);

  OneSignal.Notifications.requestPermission(true);

  // Handle notification tap while app is in foreground
  OneSignal.Notifications.addClickListener((event) {
    final data = event.notification.additionalData;
    debugPrint('Notification Clicked. Data: $data');
    // TODO: Use a global NavigatorKey to push to specific screens based on data.
  });
}

void _syncUserWithOneSignal(User user) {
  OneSignal.login(user.uid);

  if (user.email != null) {
    OneSignal.User.addEmail(user.email!);
  }

  if (user.displayName != null) {
    OneSignal.User.addTags({"name": user.displayName!});
  }
}